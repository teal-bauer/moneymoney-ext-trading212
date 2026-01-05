# Trading 212 for MoneyMoney

[English](#english) | [Deutsch](#deutsch)

---

## English

### ⚠️ Important: Use Release Versions Only

**ONLY use release-tagged versions of this extension.** The main branch may contain untested, broken, or incomplete code.

Download the latest release `.lua` file from the [Releases page](../../releases) and put it in your Extensions directory: https://moneymoney-app.com/extensions/

### Support Policy

**NO SUPPORT is provided for this extension.** This is a personal project shared as-is. If you need support or customizations, contact me about paid consulting.

### What This Extension Does

This extension imports your Trading 212 portfolio into MoneyMoney:

- **Cash account**: Shows your available free cash balance
- **Portfolio account**: Displays all your securities/positions with current prices and values
- **Pie accounts**: Creates separate accounts for each of your investment pies

Securities are imported with ISINs, quantities, purchase prices, and current market prices.

### Installation

1. Download the latest release `.lua` file from the [Releases page](../../releases)
2. In MoneyMoney, go to **Help → Show Database in Finder**
3. Place the downloaded `.lua` file in the **Extensions** folder
4. Restart MoneyMoney if it's running

### API Key Setup

Get a Trading 212 API key: https://helpcentre.trading212.com/hc/en-us/articles/14584770928157-Trading-212-API-key

**Required scopes**: When generating your API key in the Trading 212 mobile app, enable these read scopes:
- `account` - for account information and cash balances
- `portfolio` - for your open positions and holdings
- `metadata` - for instrument details (ISINs, tickers, names)
- `pies:read` - for pie portfolios (if you use pies)

You will receive both an **API Key** and an **API Secret**.

Add an account of type "Trading 212" in MoneyMoney:
- Enter your **API Key** as the username
- Enter your **API Secret** as the password

#### Caveats

**Currency conversion:** If you hold securities in currencies different from your account currency (e.g., US stocks in a EUR account), values may differ slightly from the Trading 212 app. The API provides prices in the instrument's native currency but doesn't include exchange rates, so MoneyMoney uses its own rates which may not match Trading 212's exactly.

**Data freshness:** Portfolio data is cached briefly to avoid API rate limits, so values may lag behind real-time prices by a minute or two.

### Troubleshooting

If something isn't working, check MoneyMoney's log window (**Window → Log Window** or **Cmd-L**) for error messages. Common issues are usually related to API scope permissions or network connectivity.

### License

This extension is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

---

## Deutsch

### ⚠️ Wichtig: Nur Release-Versionen verwenden

**Verwenden Sie NUR Release-Versionen dieser Erweiterung.** Der main-Branch kann ungetesteten, fehlerhaften oder unvollständigen Code enthalten.

Laden Sie die neueste Release-`.lua`-Datei von der [Releases-Seite](../../releases) herunter und legen Sie sie in Ihr Extensions-Verzeichnis: https://moneymoney-app.com/extensions/

### Support-Richtlinien

**Es wird KEIN SUPPORT für diese Erweiterung angeboten.** Dies ist ein persönliches Projekt, das wie besehen geteilt wird. Wenn Sie Support oder Anpassungen benötigen, kontaktieren Sie mich für bezahlte Beratung.

### Was diese Erweiterung macht

Diese Erweiterung importiert Ihr Trading 212 Portfolio in MoneyMoney:

- **Cash-Konto**: Zeigt Ihr verfügbares freies Barguthaben
- **Portfolio-Konto**: Zeigt alle Ihre Wertpapiere/Positionen mit aktuellen Kursen und Werten
- **Pie-Konten**: Erstellt separate Konten für jeden Ihrer Investment-Pies

Wertpapiere werden mit ISINs, Mengen, Kaufpreisen und aktuellen Marktpreisen importiert.

### Installation

1. Laden Sie die neueste Release-`.lua`-Datei von der [Releases-Seite](../../releases) herunter
2. Gehen Sie in MoneyMoney zu **Hilfe → Datenbank im Finder zeigen**
3. Legen Sie die heruntergeladene `.lua`-Datei im **Extensions**-Ordner ab
4. Starten Sie MoneyMoney neu, falls es läuft

### API-Key-Einrichtung

Erstellen Sie einen Trading 212 API-Key: https://helpcentre.trading212.com/hc/en-us/articles/14584770928157-Trading-212-API-key

**Erforderliche Scopes**: Aktivieren Sie beim Erstellen Ihres API-Keys in der Trading 212 Mobile-App diese Lese-Scopes:
- `account` - für Kontoinformationen und Barguthaben
- `portfolio` - für Ihre offenen Positionen und Bestände
- `metadata` - für Instrumentendetails (ISINs, Ticker, Namen)
- `pies:read` - für Pie-Portfolios (falls Sie Pies verwenden)

Sie erhalten sowohl einen **API Key** als auch ein **API Secret**.

Fügen Sie in MoneyMoney ein Konto vom Typ "Trading 212" hinzu:
- Geben Sie Ihren **API Key** als Benutzernamen ein
- Geben Sie Ihr **API Secret** als Passwort ein

#### Einschränkungen

**Währungsumrechnung:** Wenn Sie Wertpapiere in anderen Währungen als Ihrer Kontowährung halten (z.B. US-Aktien in einem EUR-Konto), können die Werte leicht von der Trading 212 App abweichen. Die API liefert Preise in der nativen Währung des Instruments, enthält aber keine Wechselkurse, daher verwendet MoneyMoney eigene Kurse, die möglicherweise nicht exakt mit denen von Trading 212 übereinstimmen.

**Datenaktualität:** Portfoliodaten werden kurzzeitig gecacht, um API-Ratenlimits zu vermeiden, sodass Werte um ein bis zwei Minuten hinter Echtzeitkursen zurückliegen können.

### Fehlerbehebung

Wenn etwas nicht funktioniert, prüfen Sie MoneyMoneys Log-Fenster (**Fenster → Log-Fenster** oder **Cmd-L**) auf Fehlermeldungen. Häufige Probleme hängen meist mit API-Scope-Berechtigungen oder Netzwerkverbindung zusammen.

### Lizenz

Diese Erweiterung ist unter der Apache License 2.0 lizenziert. Siehe die [LICENSE](LICENSE)-Datei für Details.
