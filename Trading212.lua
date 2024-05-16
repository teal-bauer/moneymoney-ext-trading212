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

WebBanking{version     = 0.1,
           url         = "https://trading212.com/",
           services    = {"Trading 212"},
           description = "Trading 212"}

local connection = Connection()
local currency
local api_key
local instruments

-- Helpers

function dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
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
  nh = tonumber(h)
  nm = tonumber(m)
  if dateStr:sub(-1) ~= "Z" then
    local sign, oh, om = string.match(dateStr, "([-+])(%d%d):(%d%d)$")
    nh = nh + tonumber(sign .. oh)
    nm = nm + tonumber(sign .. om)
  end
  return os.time({
    year=tonumber(Y),
    month=tonumber(M),
    day=tonumber(D),
    hour=nh,
    min=nm,
    sec=tonumber(s)
  })
end

-- WebBanking API impl

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Trading 212"
end  

function InitializeSession (protocol, bankCode, username, reserved, password)
  api_key = password  
  
  MM.printStatus("Getting instrument list")
  MM.sleep(5)
  content = connection:request(
    "GET",
    "https://live.trading212.com/api/v0/equity/metadata/instruments",
    "", "",
    {
      Accept = "application/json",
      Authorization = api_key,
    }
  )
  instruments_list = JSON(content):dictionary()
  instruments = {}
  for k, v in pairs(instruments_list) do
    instruments[v["ticker"]] = v
  end

  MM.printStatus("Getting account information")
  MM.sleep(2)
  content = connection:request(
    "GET",
    "https://live.trading212.com/api/v0/equity/account/info",
    "",
    "",
    {
      Accept = "application/json",
      Authorization = api_key,
    }
  )
  account_info = JSON(content):dictionary()
  currency = account_info["currencyCode"]

  return nil
end

function ListAccounts (knownAccounts)
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
  return {cashAccount, portfolioAccount, piesAccount}
end

function RefreshAccount (account, since)
  MM.printStatus("Refreshing account " .. account["accountNumber"])
  if account["accountNumber"] == "Trading 212 Cash" then
    content = connection:request("GET", "https://live.trading212.com/api/v0/equity/account/cash", "", "",
      {
        Accept = "application/json",
        Authorization = api_key,
      }
    )
    json = JSON(content):dictionary()
    return {balance=json["free"], transactions={}}
  end
  if account["accountNumber"] == "Trading 212 Portfolio" then
    MM.sleep(5)
    MM.printStatus("Fetching Portfolio")
    content = connection:request("GET", "https://live.trading212.com/api/v0/equity/portfolio", "", "",
      {
        Accept = "application/json",
        Authorization = api_key,
      }
    )
    json = JSON(content):dictionary()
    -- print(dump(json))
    local transactions = {}
    for k, v in pairs(json) do
      local instr = instruments[v["ticker"]]
      -- pies are shown separately
      local q = v["quantity"] - v["pieQuantity"]
      if q > 0.0 then
        table.insert(
          transactions,
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
    return {securities = transactions}
  end
  if account["accountNumber"] == "Trading 212 Pies" then
    MM.printStatus("Fetching pies")
    MM.sleep(5) -- rate limit
    content = connection:request("GET", "https://live.trading212.com/api/v0/equity/pies", "", "",
      {
        Accept = "application/json",
        Authorization = api_key,
      }
    )
    json = JSON(content):dictionary()
    -- print(dump(json))
    local transactions = {}
    for k, v in pairs(json) do
      MM.printStatus("Getting info for pie " .. v["id"])
      MM.sleep(5) -- rate limit
      content = connection:request("GET", "https://live.trading212.com/api/v0/equity/pies/" .. v["id"], "", "",
        {
          Accept = "application/json",
          Authorization = api_key,
        }
      )
      pie_info = JSON(content):dictionary()
      table.insert(transactions, {
        name = pie_info["settings"]["name"],
        quantity = 1,
        amount = v["result"]["value"],
        purchasePrice = v["result"]["investedValue"],
      })
    end
    return {securities = transactions}
  end
end

function EndSession ()
  -- Logout.
end
