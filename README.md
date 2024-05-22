# Trading 212 for MoneyMoney

Download the `.lua` file and put it in your Extensions directory: https://moneymoney-app.com/extensions/

Get a Trading 212 API key: https://helpcentre.trading212.com/hc/en-us/articles/14584770928157-How-can-I-generate-an-API-key

The key needs all read scopes.

Add an account of type "Trading 212" in MoneyMoney, enter your API key as your username and anything as password.
If you have a new enough version of MoneyMoney, it will ask for the API key directly.

### Caveats

Some values might not be congruent to what the mobile app shows you, either due to data staleness or due to weird currency handling. I haven't found a good way to handle this correctly; the T212 API is just weird in this regard. If you have an idea on how to handle this better, PRs are welcome.
