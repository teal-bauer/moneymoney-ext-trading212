# Trading 212 for MoneyMoney

Download the `.lua` file and put it in your Extensions directory: https://moneymoney-app.com/extensions/

Get a Trading 212 API key: https://helpcentre.trading212.com/hc/en-us/articles/14584770928157-How-can-I-generate-an-API-key

The key needs all read scopes.

Add an account of type "Trading 212" in MoneyMoney, log in with any username and the API key as password.

### Caveats

There is very little error handling. If things fail, double check your API key, and try again.

Currency handling is not 100% right due to limitations in the Trading 212 API. Especially Pies are returning confusing values sometimes. I'm looking for workarounds.

Pies should probably be modelled as separate accounts with their own portfolios.
