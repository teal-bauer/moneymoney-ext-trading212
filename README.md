# Trading 212 for MoneyMoney

Download the `.lua` file and put it in your Extensions directory: https://moneymoney-app.com/extensions/

Get a Trading 212 API key: https://helpcentre.trading212.com/hc/en-us/articles/14584770928157-How-can-I-generate-an-API-key

The key needs all read scopes. You will receive both an **API Key** and an **API Secret**.

Add an account of type "Trading 212" in MoneyMoney:
- Enter your **API Key** as the username
- Enter your **API Secret** as the password

### Caveats

**Currency conversion:** If you hold securities in currencies different from your account currency (e.g., US stocks in a EUR account), values may differ slightly from the Trading 212 app. The API provides prices in the instrument's native currency but doesn't include exchange rates, so MoneyMoney uses its own rates which may not match Trading 212's exactly.

**Data freshness:** Portfolio data is cached briefly to avoid API rate limits, so values may lag behind real-time prices by a minute or two.
