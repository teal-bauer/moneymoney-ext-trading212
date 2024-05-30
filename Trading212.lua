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
  version     = 0.31,
  url         = "https://trading212.com/",
  services    = { "Trading 212" },
  description = "Trading 212"
}

local connection = Connection()
local api_key

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

function split(str, sep)
  if sep == nil then
    sep = "%s"
  end
  local substrings = {}
  for substring in string.gmatch(str, "([^"..sep.."]+)") do
    table.insert(substrings, substring)
  end
  return substrings
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
function Cached(key, ttl, updateFunction, ...)
  if not LocalStorage[api_key] then
    LocalStorage[api_key] = {}
  end
  if not LocalStorage[api_key][key] then
    LocalStorage[api_key][key] = {}
  end

  local cacheEntry = LocalStorage[api_key][key]
  local cachedData = cacheEntry.data
  local expirationTime = cacheEntry.expires_at
  if cachedData and expirationTime and os.time() < expirationTime then
    return cachedData
  end

  local updatedData = updateFunction(...)

  cacheEntry.data = updatedData
  cacheEntry.expires_at = os.time() + ttl

  return updatedData
end

function CleanupCache()
  local currentTime = os.time()

  for api_key, scoped_cache in pairs(LocalStorage) do
    print("Cleanup - Checking API key: " .. api_key)
    for key, cacheEntry in pairs(scoped_cache) do
      print("Cleanup - Checking key: " .. key)
      if type(cacheEntry) == "table" and ((cacheEntry.expires_at and currentTime >= cacheEntry.expires_at) or (not cacheEntry.expires_at)) then
        print("Cleanup - Expiring key: " .. key)
        LocalStorage[api_key][key] = nil
      end
    end
    if LocalStorage[api_key] == {} then
      print("Cleanup - Expiring API key " .. api_key)
      LocalStorage[api_key] = nil
    end
  end
end

-- API wrapper with exponential backoff
function ApiRequest(url)
  local max_attempts = 5
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
    elseif response["error"] == 403 then
      error("Your API key does not have the correct scope(s) for this request @ " .. url)
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
function FetchInstruments()
  local instruments_response = ApiRequest("https://live.trading212.com/api/v0/equity/metadata/instruments")
  local instruments_tbl = {}
  for k, v in pairs(instruments_response) do
    instruments_tbl[v["ticker"]] = v
  end
  return instruments_tbl
end

function FetchAccountInfo()
  return ApiRequest("https://live.trading212.com/api/v0/equity/account/info")
end

function FetchPortfolio()
  local response = ApiRequest("https://live.trading212.com/api/v0/equity/portfolio")
  local instruments = Cached("instruments", 86400, FetchInstruments)
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

function FetchAccountCash()
  return ApiRequest("https://live.trading212.com/api/v0/equity/account/cash")
end

function FetchPies()
  -- [
  --   {
  --     "cash": 0,
  --     "dividendDetails": {
  --       "gained": 0,
  --       "inCash": 0,
  --       "reinvested": 0
  --     },
  --     "id": 0,
  --     "progress": 0.5,
  --     "result": {
  --       "investedValue": 0,
  --       "result": 0,
  --       "resultCoef": 0,
  --       "value": 0
  --     },
  --     "status": "AHEAD"
  --   }
  -- ]
  return ApiRequest("https://live.trading212.com/api/v0/equity/pies")
end

function FetchPie(pie_id)
  -- {
  --   "instruments": [
  --     {
  --       "currentShare": 0,
  --       "expectedShare": 0,
  --       "issues": [
  --         {
  --           "name": "DELISTED",
  --           "severity": "IRREVERSIBLE"
  --         }
  --       ],
  --       "ownedQuantity": 0,
  --       "result": {
  --         "investedValue": 0,
  --         "result": 0,
  --         "resultCoef": 0,
  --         "value": 0
  --       },
  --       "ticker": "string"
  --     }
  --   ],
  --   "settings": {
  --     "creationDate": "2019-08-24T14:15:22Z",
  --     "dividendCashAction": "REINVEST",
  --     "endDate": "2019-08-24T14:15:22Z",
  --     "goal": 0,
  --     "icon": "Home",
  --     "id": 0,
  --     "initialInvestment": 0,
  --     "instrumentShares": {
  --       "property1": 0,
  --       "property2": 0
  --     },
  --     "name": "string",
  --     "pubicUrl": "string"
  --   }
  -- }
  return ApiRequest("https://live.trading212.com/api/v0/equity/pies/" .. tostring(pie_id))
end

function PieToPortfolio(pie_info)
  local instruments = Cached("instruments", 86400, FetchInstruments)
  -- local portfolio = Cached("portfolio", 60, FetchPortfolio)
  local securities = {}
  for k, v in pairs(pie_info["instruments"]) do
    local instr = instruments[v["ticker"]]
    table.insert(
      securities,
      {
        name = instr["name"],
        isin = instr["isin"],
        quantity = v["ownedQuantity"],
        -- currencyOfQuantity = nil,
        -- purchasePrice = v["averagePrice"],
        -- currencyOfPurchasePrice = instr["currencyCode"],
        -- price = v["currentPrice"],
        -- currencyOfPrice = instr["currencyCode"],
        amount = v["result"]["value"],
        originalAmount = v["result"]["investedValue"],
        -- currencyOfOriginalAmount = instr["currencyCode"],
        -- tradeTimestamp = IsotimeToUnixtime(v["initialFillDate"]),
      }
    )
  end

  return securities
end

-- WebBanking API impl

function SupportsBank(protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Trading 212"
end

function InitializeSession(protocol, bankCode, username, reserved, password)
  api_key = username

  MM.printStatus("Cleaning up local cache")
  CleanupCache()

  MM.printStatus("Getting account information")
  Cached("account_info", 86400, FetchAccountInfo)

  MM.printStatus("Getting available instruments")
  Cached("instruments", 86400, FetchInstruments)

  return nil
end

function ListAccounts(knownAccounts)
  MM.printStatus("Fetching accounts")
  local account_info = Cached("account_info", 86400, FetchAccountInfo)
  local acct_no = tostring(account_info["id"])
  local accounts = {
    {
      name = "Cash",
      accountNumber = acct_no,
      subAccount = "CASH",
      currency = account_info["currencyCode"],
      type = AccountTypeSavings
    },
    {
      name = "Portfolio",
      accountNumber = acct_no,
      subAccount = "PORTFOLIO",
      currency = account_info["currencyCode"],
      type = AccountTypePortfolio,
      portfolio = true
    }
  }

  local pies = Cached("pies", 60, FetchPies)
  for k, v in pairs(pies) do
    MM.sleep(2)
    local pie_detail = Cached("pie_" .. tostring(v["id"]), 60, FetchPie, v["id"])
    print(dump(pie_detail["settings"]))
    local piesAccount = {
      name = "Pie " .. pie_detail["settings"]["name"],
      accountNumber = acct_no,
      subAccount = "PIE_" .. tostring(v["id"]),
      currency = account_info["currencyCode"],
      type = AccountTypePortfolio,
      portfolio = true
    }
    table.insert(accounts, piesAccount)
  end

  return accounts
end

function RefreshAccount(account, since)
  MM.printStatus("Refreshing account " .. account["accountNumber"] .. "/" .. account["subAccount"])

  -- Free cash - TODO: Add withdrawals / investments
  if account["subAccount"] == "CASH" then
    local account_cash = Cached("account_cash", 10, FetchAccountCash)
    return { balance = account_cash["free"], transactions = {} }
  end

  -- Main portfolio
  if account["subAccount"] == "PORTFOLIO" then
    MM.printStatus("Fetching Portfolio")
    local portfolio = Cached("portfolio", 60, FetchPortfolio)
    return { securities = portfolio }
  end

  -- Pies
  if account["subAccount"]:sub(1,3) == "PIE" then
    local pie_id = account["subAccount"]:sub(5, #account["subAccount"])
    local pie_detail = Cached("pie_" .. pie_id, 60, FetchPie, pie_id)
    local pie_as_portfolio = PieToPortfolio(pie_detail)
    return { securities = pie_as_portfolio }
  end

  return nil
end

function EndSession()
  -- Logout - nothing to do.
end

-- SIGNATURE: MCwCFECsBiVxvZZddOKACvZgjMgGYwWBAhQvIt29L3MhiL5+RAFwfoMLwr7V5w==
