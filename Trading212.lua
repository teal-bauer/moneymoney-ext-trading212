--
-- MoneyMoney Extension for Trading 212 <https://trading212.com/>
-- https://github.com/teal-bauer/moneymoney-ext-trading212/
--

--
-- Copyright 2024 Teal Bauer <opensource+mm-t212@teal.is>
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

WebBanking{
  version     = 0.2,
  url         = "https://trading212.com/",
  services    = { "Trading 212" },
  description = "Trading 212"
}

local connection = Connection()
local currency
local api_key
local instruments

-- Helpers

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

function IsotimeToUnixtime(dateStr)
  -- Iso datetime like "2021-01-11T18:21:13.000+02:00"
  -- to Unix timestamp
  local Y, M, D, h, m, s, ms = string.match(dateStr, "(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d).(%d%d%d)")
  local nh = tonumber(h)
  local nm = tonumber(m)
  if dateStr:sub(-1) ~= "Z" then
    local sign, oh, om = string.match(dateStr, "([-+])(%d%d):(%d%d)$")
    nh = nh + tonumber(sign .. oh)
    nm = nm + tonumber(sign .. om)
  end
  return os.time({
    year = tonumber(Y),
    month = tonumber(M),
    day = tonumber(D),
    hour = nh,
    min = nm,
    sec = tonumber(s)
  })
end

-- Memoization
function Cached(key, ttl, updateFunction)
  if not LocalStorage[key] then
    LocalStorage[key] = {}
  end

  local cacheEntry = LocalStorage[key]
  local cachedData = cacheEntry.data
  local expirationTime = cacheEntry.expires_at
  if cachedData and expirationTime and os.time() < expirationTime then
    return cachedData
  end

  local updatedData = updateFunction()

  cacheEntry.data = updatedData
  cacheEntry.expires_at = os.time() + ttl

  return updatedData
end

function CleanupCache()
  local currentTime = os.time()

  for key, cacheEntry in pairs(LocalStorage) do
    print("Cleanup - Checking key: " .. key)
    if type(cacheEntry) == "table" and (cacheEntry.expires_at and currentTime >= cacheEntry.expires_at) or (not cacheEntry.expires_at) then
      print("Expiring key " .. key)
      LocalStorage[key] = nil
    end
  end
end

-- API wrapper
function ApiRequest(url)
  local max_attempts = 4
  local initial_delay = 5
  local response

  for attempt = 0, max_attempts do
    if attempt > 0 then
      local delay = initial_delay * (2 ^ (attempt - 1))
      print("Rate limit exceeded - sleeping for " .. delay .. " seconds")
      MM.sleep(delay)
    end
    local content, charset, mimeType, filename, headers = connection:request(
      "GET", url, "", "",
      {
        Accept = "application/json",
        Authorization = api_key,
      }
    )
    response = JSON(content):dictionary()
    if response["error"] == 401 then
      error(LoginFailed)
    elseif response["code"] == "InternalError" then
      error("Internal server error, please try again later")
    elseif response["code"] == "BusinessException" and response["context"]["type"] == "TooManyRequests" then
      -- do nothing, restart loop
    else
      return response
    end
  end

  -- fell through after max_attempts
  error("Request failed after " .. max_attempts .. " tries: " .. dump(response))
end

-- Data fetching methods
function RefreshInstruments()
  local instruments_response = ApiRequest("https://live.trading212.com/api/v0/equity/metadata/instruments")
  local instruments_tbl = {}
  for k, v in pairs(instruments_response) do
    instruments_tbl[v["ticker"]] = v
  end
  return instruments_tbl
end

function RefreshAccountInfo()
  return ApiRequest("https://live.trading212.com/api/v0/equity/account/info")
end

function RefreshPortfolio()
  local response = ApiRequest("https://live.trading212.com/api/v0/equity/portfolio")
  local securities = {}
  for k, v in pairs(response) do
    local instr = instruments[v["ticker"]]
    -- pies are shown separately
    local q = v["quantity"] - v["pieQuantity"]
    if q > 0.0 then
      table.insert(
        securities,
        {
          name = instr["name"],
          isin = instr["isin"],
          quantity = q,
          currencyOfQuantity = nil,
          purchasePrice = v["averagePrice"],
          currencyOfPurchasePrice = instr["currencyCode"],
          price = v["currentPrice"],
          currencyOfPrice = instr["currencyCode"],
          -- amount = (v["quantity"] * v["currentPrice"]) + v["ppl"] + v["fxPpl"],
          originalAmount = q * v["currentPrice"],
          currencyOfOriginalAmount = instr["currencyCode"],
          tradeTimestamp = IsotimeToUnixtime(v["initialFillDate"]),
        }
      )
    end

    -- String name: Bezeichnung des Wertpapiers
    -- String isin: ISIN
    -- String securityNumber: WKN
    -- Number quantity: Nominalbetrag oder Stückzahl
    -- String currencyOfQuantity: Währung bei Nominalbetrag oder nil bei Stückzahl
    -- Number purchasePrice: Kaufpreis oder Kaufkurs
    -- String currencyOfPurchasePrice: Von der Kontowährung abweichende Währung des Kaufpreises
    -- Number exchangeRateOfPurchasePrice: Wechselkurs zum Kaufzeitpunkt
    -- Number price: Aktueller Preis oder Kurs
    -- String currencyOfPrice: Von der Kontowährung abweichende Währung des Preises
    -- Number exchangeRateOfPrice: Aktueller Wechselkurs
    -- Number amount: Wert der Depotposition in Kontowährung
    -- Number originalAmount: Wert der Depotposition in Originalwährung
    -- String currencyOfOriginalAmount: Originalwährung
    -- String market: Name des Börsenplatzes
    -- Number tradeTimestamp: Notierungszeitpunkt; Die Angabe erfolgt in Form eines POSIX-Zeitstempels.
  end

  return securities
end

function RefreshAccountCash()
  return ApiRequest("https://live.trading212.com/api/v0/equity/account/cash")
end

function RefreshPies()
  return ApiRequest("https://live.trading212.com/api/v0/equity/pies")
end

-- WebBanking API impl

function SupportsBank(protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Trading 212"
end

function InitializeSession(protocol, bankCode, username, reserved, password)
  api_key = username

  MM.printStatus("Cleaning up local cache")
  CleanupCache()

  MM.printStatus("Getting instrument list")
  instruments = Cached("instruments", 86400, RefreshInstruments)

  MM.printStatus("Getting account information")
  currency = Cached("account_info", 86400, RefreshAccountInfo)["currencyCode"]

  return nil
end

function ListAccounts(knownAccounts)
  MM.printStatus("Fetching accounts")
  -- Return array of accounts.
  local cashAccount = {
    name = "Trading 212 Cash",
    accountNumber = "Trading 212 Cash",
    currency = currency,
    type = AccountTypeSavings
  }
  local portfolioAccount = {
    name = "Trading 212 Portfolio",
    accountNumber = "Trading 212 Portfolio",
    currency = currency,
    type = AccountTypePortfolio,
    portfolio = true
  }
  local piesAccount = {
    name = "Trading 212 Pies",
    accountNumber = "Trading 212 Pies",
    currency = currency,
    type = AccountTypePortfolio,
    portfolio = true
  }

  return { cashAccount, portfolioAccount, piesAccount }
end

function RefreshAccount(account, since)
  MM.printStatus("Refreshing account " .. account["accountNumber"])

  -- Free cash - TODO: Add withdrawals / investments
  if account["accountNumber"] == "Trading 212 Cash" then
    local cash_info = Cached("account_cash", 10, RefreshAccountCash)
    return { balance = cash_info["free"], transactions = {} }
  end

  -- Main portfolio
  if account["accountNumber"] == "Trading 212 Portfolio" then
    MM.printStatus("Fetching Portfolio")
    local portfolio = RefreshPortfolio()
    return { securities = portfolio }
  end

  -- Pies
  if account["accountNumber"] == "Trading 212 Pies" then
    MM.printStatus("Fetching pies")
    local pies = Cached("pies", 60, RefreshPies)
    local pie_values = {}
    for k, v in pairs(pies) do
      print(dump(v))
      MM.printStatus("Getting info for pie " .. v["id"])
      local pie_info = ApiRequest("https://live.trading212.com/api/v0/equity/pies/" .. v["id"])
      table.insert(pie_values, {
        name = pie_info["settings"]["name"],
        quantity = 1,
        amount = v["result"]["value"],
        purchasePrice = v["result"]["investedValue"],
      })
    end

    return {
      securities = pie_values
    }
  end
end

function EndSession()
  -- Logout - nothing to do.
end
