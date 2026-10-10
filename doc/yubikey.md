# YubiKey

Postup pro zprovoznění YubiKey 5C NFC (FW 5.7.4) pro PGP, FIDO2/passkeys, TOTP a SSH na Ubuntu 26.04.

Applety, které po nastavení zůstávají zapnuté: **OpenPGP** (USB), **FIDO2** (USB + NFC), **OATH** (USB + NFC). Vypnuté: Yubico OTP, FIDO U2F, PIV, YubiHSM Auth.

Rozdělení rolí je záměrné: PGP řeší podpisy commitů a šifrování, FIDO2 řeší SSH i passkeys, OATH řeší TOTP kódy. SSH tedy **nejede přes gpg-agent** — `enable-ssh-support` zůstává vypnuté, aby to nekolidovalo se stávajícím `ssh-agent-load-keys` setupem ve stow balíku `ssh-agent`.

## 1. Smartcard vrstva

Bez `pcscd` hlásí `ykman` chybu `PC/SC not available` a applety OpenPGP i OATH jsou nedostupné.

```bash
sudo apt install pcscd pcsc-tools scdaemon
sudo systemctl enable --now pcscd
```

`scdaemon` má vlastní vestavěný CCID driver, který si s `pcscd` přetahuje výlučný přístup ke kartě. `disable-ccid` ho donutí jít přes PC/SC:

```bash
mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
echo 'disable-ccid' >> ~/.gnupg/scdaemon.conf
```

Ověření (nesmí být žádný warning): `ykman info`

## 2. Applety

```bash
ykman config usb --enable OATH --disable OTP
ykman config nfc --enable OATH
```

Klíč se po každém příkazu odpojí a znovu přihlásí. Yubico OTP je ten applet, který při náhodném dotyku vyplivne dlouhý řetězec do aktivního okna — pro tenhle setup není potřeba.

## 3. PGP

### 3.1 PINy

Tovární hodnoty jsou `123456` (user) a `12345678` (admin).

```bash
ykman openpgp access change-pin          # user PIN, min. 6 znaků
ykman openpgp access change-admin-pin    # admin PIN, min. 8 znaků
ykman openpgp access change-reset-pin    # reset code — odemkne zablokovaný user PIN
ykman openpgp access set-retries 3 3 3
```

User PIN se zadává při každém podpisu. Admin PIN jen při správě karty — patří do password manageru, protože se používá zřídka a zapomene se.

### 3.2 Generování mimo kartu

Klíče se generují mimo YubiKey, aby existovala záloha. Bez ní znamená ztráta klíče i ztrátu schopnosti rozšifrovat cokoliv, co bylo zašifrováno na tento klíč. Celý proces běží v `GNUPGHOME` na tmpfs, aby soukromý klíč nikdy nesedl na disk:

```bash
export GNUPGHOME=$(mktemp -d -p /dev/shm yk.XXXXXX)
chmod 700 "$GNUPGHOME"
```

Tenhle shell musí zůstat otevřený do konce kapitoly 3 — po jeho zavření zmizí `GNUPGHOME` z prostředí a další příkazy začnou sahat na `~/.gnupg`.

Master klíč (jen certify, bez expirace) a tři subkeys s dvouletou expirací:

```bash
gpg --quick-generate-key "Jan Trojak <trojakjan24@gmail.com>" ed25519 cert never
FPR=$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/ {print $10; exit}')

gpg --quick-add-uid "$FPR" "Jan Trojak <jan.trojak@recombee.com>"
gpg --quick-add-uid "$FPR" "Jan Trojak <jantrojak@ext.isee.ai>"

gpg --quick-add-key "$FPR" ed25519 sign 2y
gpg --quick-add-key "$FPR" cv25519 encr 2y
gpg --quick-add-key "$FPR" ed25519 auth 2y
```

Všechny tři UIDs sedí na jednom klíči, takže jeden `signingkey` pokryje osobní i pracovní identity a do `recombee.gitconfig` ani `isee.gitconfig` se podepisovací konfigurace přidávat nemusí.

### 3.3 Záloha

```bash
cd "$GNUPGHOME"
gpg --armor --export-secret-keys "$FPR"    > master-secret.asc
gpg --armor --export-secret-subkeys "$FPR" > subkeys-secret.asc
gpg --armor --export "$FPR"                > public.asc
cp openpgp-revocs.d/"$FPR".rev             revocation-cert.asc

tar czf - master-secret.asc subkeys-secret.asc public.asc revocation-cert.asc \
  | gpg --symmetric --cipher-algo AES256 -o ~/yubikey-pgp-backup.tar.gz.gpg
```

Archiv patří na offline médium (ideálně dvě, uložená odděleně od klíče) — přesunout, ne zkopírovat. Ověření, že jde rozbalit, proběhne **před** dalším krokem, protože ten klíče z disku nenávratně smaže:

```bash
gpg -d /media/.../yubikey-pgp-backup.tar.gz.gpg | tar tzf -
```

### 3.4 Přesun subkeys na kartu

```bash
gpg --edit-key "$FPR"
```

```
gpg> key 1
gpg> keytocard        → 1 (Signature key)
gpg> key 1            ← odznačí key 1
gpg> key 2
gpg> keytocard        → 2 (Encryption key)
gpg> key 2
gpg> key 3
gpg> keytocard        → 3 (Authentication key)
gpg> save
```

`keytocard` klíč přesune, nezkopíruje — lokální kopie zanikne.

### 3.5 Import do skutečného keyringu

```bash
cp "$GNUPGHOME/public.asc" ~/yk-public.asc
unset GNUPGHOME
gpg --import ~/yk-public.asc
gpg --card-status
FPR=$(gpg --list-keys --with-colons | awk -F: '/^fpr:/ {print $10; exit}')
gpg --edit-key "$FPR"    # → trust → 5 (ultimate) → quit

gpgconf --kill gpg-agent
rm -rf /dev/shm/yk.*
```

`gpg --card-status` vytvoří v `~/.gnupg` stuby, které ukazují na kartu místo na skutečný klíčový materiál.

### 3.6 Touch policy

```bash
ykman openpgp keys set-touch sig on     # nebo: cached
ykman openpgp keys set-touch enc on
ykman openpgp keys set-touch aut on
```

`on` vyžaduje dotyk při každé operaci. `cached` drží dotyk 15 sekund, což u `git rebase` přes dvacet commitů znamená jeden dotyk místo dvaceti.

`fixed` nepoužívat — nejde vrátit bez resetu celého OpenPGP appletu, tedy bez ztráty klíčů na kartě.

Test: `echo test | gpg --clearsign` musí chtít PIN a dotyk.

## 4. SSH

```bash
ssh-keygen -t ed25519-sk \
  -O resident \
  -O verify-required \
  -O application=ssh:zezav \
  -C "yubikey-32875718" \
  -f ~/.ssh/id_ed25519_sk
```

`resident` uloží klíč na YubiKey, takže se na novém stroji vytáhne přes `ssh-keygen -K` a nezávisí na souboru v `~/.ssh`. `verify-required` vynutí PIN i dotyk.

Nový klíč patří do `stow/ssh-agent/.config/ssh-agent/keys.conf`:

```
~/.ssh/id_ed25519_sk
```

Stávající klíče zůstávají funkční; migrace jednotlivých služeb na nový klíč je postupná.

## 5. Git podepisování

Hotovo, v repu: `stow/git/.config/git/core.gitconfig`.

```ini
[user]
  signingkey = 0xE8F8EF0B655EAAB3!
[gpg]
  format = openpgp
[commit]
  gpgsign = false
[tag]
  gpgsign = false
```

ID se vytáhne z `gpg --list-secret-keys --keyid-format=long`, řádek `ssb> ed25519 ... [S]`. Vykřičník za ID je podstatný — bez něj si gpg vybere subkey sám.

Podepisování je **defaultně vypnuté**: většinu commitů tady dělají AI agenti v neinteraktivních sessions a každý podpis chce fyzický dotyk YubiKeye, takže by se na něm session zasekla. Klíč je nakonfigurovaný, jen se nepoužívá automaticky — podepisuje se vědomě přes `git commit -S`. Na dodatečné podepsání posledního commitu (typicky takového, který udělal agent bez podpisu) je v `core.gitconfig` git alias `resign`:

```ini
[alias]
  resign = commit --amend --no-edit -S
```

Takže `git commit -S` nebo `git resign` podepisuje, `git commit` ne.

Konfigurace sedí v `core.gitconfig`, takže platí i pro isee identitu (`~/dev/isee/`). V `recombee.gitconfig` je vypnutí navíc ještě explicitně, protože klíč **nakonec dostal jen dvě UID** — `trojakjan24@gmail.com` a `jantrojak@ext.isee.ai`. Podpis nad commitem s adresou `jan.trojak@recombee.com` by se hlásil jako Unverified. Pozor, explicitní `-S` (`git commit -S`, `git resign`) má přednost i nad tím, takže v Recombee repu se podepisovat nemá. Až UID přibude (viz níže), je ten blok v `recombee.gitconfig` zbytečný.

Doplnění chybějícího UID vyžaduje master klíč, který na disku není (`sec#` = jen stub):

```bash
export GNUPGHOME=$(mktemp -d -p /dev/shm yk.XXXXXX) && chmod 700 "$GNUPGHOME"
gpg --import master-secret.asc            # ze zálohy podle 3.3
gpg --quick-add-uid "$FPR" "Jan Trojak <jan.trojak@recombee.com>"
gpg --armor --export "$FPR" > public.asc  # znovu naimportovat do ~/.gnupg a nahrát do GitLabu
```

Veřejný klíč pro GitHub/GitLab: `gpg --armor --export "$FPR"`

Ověření, že podepisování jede: `echo test | gpg --clearsign` (chce PIN i dotyk), pak `git log --show-signature -1`.

## 6. TOTP

```bash
ykman oath access change                      # heslo pro OATH applet (volitelné)
ykman oath accounts add -t github:tvuj-login  # -t = vyžaduje dotyk
ykman oath accounts code
```

`add` chce base32 secret, který služba nabízí pod odkazem typu „can't scan QR code". Na telefonu to samé obslouží Yubico Authenticator přes NFC — proto je OATH zapnuté i nad NFC.

Recovery kódy od každé služby je nutné si uchovat zvlášť. OATH secrets z YubiKey ven nedostaneš.

## 7. Passkeys

FIDO2 PIN a `Always Require UV` jsou na klíči už nastavené. Registrace probíhá per-službu v jejím nastavení bezpečnosti („Add passkey / security key").

```bash
ykman fido credentials list      # chce FIDO2 PIN
ykman fido credentials delete <id>
```

## 8. gpg-agent

`~/.gnupg/gpg-agent.conf`:

```
default-cache-ttl 600
max-cache-ttl 7200
pinentry-program /usr/bin/pinentry-gnome3
```

Pod Sway funguje `pinentry-gnome3`; `pinentry-curses` je fallback pro čistě terminálový provoz. Po změně `gpgconf --kill gpg-agent`.

## 9. Zanesení do repa

Hotovo:

- stow balík `stow/gnupg/.gnupg/` s `gpg.conf`, `gpg-agent.conf` a `scdaemon.conf`, zaregistrovaný v `STOW_NO_FOLDING` v `installer/config.py` — foldnout ho nelze, `~/.gnupg/` drží keyring, trustdb, stuby karty a socket agenta. Stow adresář zakládá s běžným umaskem (0755) a gpg takový home odmítá, takže `installer/steps/s06_stow.py` ho po stownutí stáhne zpět na 0700
- smartcard balíčky v `installer/config.py`: `pcsc-lite`, `pcsc-tools`, `gnupg2`, `pinentry-gnome3` (Fedora), `pcscd`, `pcsc-tools`, `scdaemon`, `pinentry-gnome3` (Debian/Ubuntu), `pcsclite`, `ccid`, `pcsc-tools`, `pinentry` (Arch). `pcscd` se aktivuje přes socket, takže se `systemctl enable` po instalaci dělat nemusí
- `yubikey-manager` (`ykman`) je v `home.nix`
- `stow/git/.config/git/core.gitconfig` a `recombee.gitconfig` podle kapitoly 5

Zbývá: SSH klíč z kapitoly 4 v `stow/ssh-agent/.config/ssh-agent/keys.conf`.

## Obnova na nový klíč

1. `gpg --import master-secret.asc` ze zálohy
2. Zopakovat kapitoly 3.1 a 3.4 na novém YubiKey
3. Pokud starý klíč mohl padnout do cizích rukou: `gpg --import revocation-cert.asc` a rozeslat na keyservery
