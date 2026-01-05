# Trading 212 for MoneyMoney

## ⚠️ Important: Use Release Versions Only

**ONLY use release-tagged versions of this extension.** The main branch may contain untested, broken, or incomplete code.

Download the latest release `.lua` file from the [Releases page](../../releases) and put it in your Extensions directory: https://moneymoney-app.com/extensions/

## Support Policy

**NO SUPPORT is provided for this extension.** This is a personal project shared as-is. If you need support or customizations, contact me about paid consulting.

## What This Extension Does

This extension imports your Trading 212 portfolio into MoneyMoney:

- **Cash account**: Shows your available free cash balance
- **Portfolio account**: Displays all your securities/positions with current prices and values
- **Pie accounts**: Creates separate accounts for each of your investment pies

Securities are imported with ISINs, quantities, purchase prices, and current market prices.

## Installation

1. Download the latest release `.lua` file from the [Releases page](../../releases)
2. In MoneyMoney, go to **Help → Show Database in Finder**
3. Place the downloaded `.lua` file in the **Extensions** folder
4. Restart MoneyMoney if it's running

## API Key Setup

Get a Trading 212 API key: https://helpcentre.trading212.com/hc/en-us/articles/14584770928157-How-can-I-generate-an-API-key

**Required scopes**: When generating your API key in the Trading 212 mobile app, enable these read scopes:
- `account` - for account information and cash balances
- `portfolio` - for your open positions and holdings
- `metadata` - for instrument details (ISINs, tickers, names)
- `pies:read` - for pie portfolios (if you use pies)

You will receive both an **API Key** and an **API Secret**.

Add an account of type "Trading 212" in MoneyMoney:
- Enter your **API Key** as the username
- Enter your **API Secret** as the password

### Caveats

**Currency conversion:** If you hold securities in currencies different from your account currency (e.g., US stocks in a EUR account), values may differ slightly from the Trading 212 app. The API provides prices in the instrument's native currency but doesn't include exchange rates, so MoneyMoney uses its own rates which may not match Trading 212's exactly.

**Data freshness:** Portfolio data is cached briefly to avoid API rate limits, so values may lag behind real-time prices by a minute or two.

## Troubleshooting

If something isn't working, check MoneyMoney's log window (**Window → Log Window** or **Cmd-L**) for error messages. Common issues are usually related to API scope permissions or network connectivity.

## License

This extension is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
