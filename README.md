(házim HOP-ra)
# Redmine telepítés Salt Stack-kel

Környezet:
* Ubuntu Server 14.04 LTS 64bit
* RVM
* Redmine 2.6
* MySQL
* Puma
* nginx

## Telepítés lépései

### Szükséges csomagok

Fejlesztőeszközök(build-essential, gcc, g++ stb): Számos Ruby gem telepítéséhez szükséges őket lefordítani. Mivel a Ruby-t nem csomagkezelőből telepítjük, hanem RVM-en keresztül, ezért annak függőségeit is figyelembe kellett venni. Számos gem-nek ezen kívül külső függőségei is vannak, mind például az Rmagick-nek az Imagemagick, a MySQL adaptereknek a `libmysqlclient-dev`, illetve a Pumának az OpenSSL.
A fejlesztőeszközökön kívül szükség van még az SVN-re, mivel azon keressztül töltjük le a Redmine legfrissebb stabil verzióját, valamint a Python MySQL lib-jére, mivel a Salt MySQL state-jei erre épülnek.

### RVM telepítése

Az RVM (Ruby Version Manager) segítségével a rendszeren egyszerre több gemset-et tarthatunk egymástól függetlenül. Másik előnye, hogy egyszerre nem csak több verziójú, hanem több Ruby implementációt is a rendszeren tarthatunk, szükség szerint ezeket egyéni fordítását is kérhetjük.
Mivel a Salt beépített RVM state-jeivel nem igazán sikerült egy nekem megfelelő környzetetet előállítani, ezért a telepítést shell script-ből oldottam meg. A kívánt környezet a következő:

* nem rendszergazda felhasználó számára telepített
* RVM "offline" telepítése, a teljes függősége egy darab tömörített fájlban van
* Ruby "offline" telepítése, mivel az RVM sosem talál előfordított verziót és mindig sajátmaga akar egyet fordítani, ami nagyon sokáig eltarthat. Lehetőség van rendszer szinten telepített Ruby "mount-olására", de sok esetben ebből problémák fakadhatnak.

A shell script a telepítés során letölti az RVM és mountolja Ruby megfelelő verzióit, amiket a fehasználó számára fel is telepít. A Ruby verziókat egy platform szerint kategorizált listából választhatjuk. Az én esetemben nem tudta a válaszott Ruby-mat validálni, ezért egy extra kapcsoló(`--verify-downloads 2`) megadása volt szükséges. Következő lépés egy gemset létrehozása és a telepített Ruby-val együtt azok alapértelmeztté tétele. Végezetül hozzáfűzzi a felhasználó `.bashrc`-jéhez a megfelelő parancsot ahhoz, hogy bejelentkezéskor az RVM környzezet automatikusan felálljon (a `source ~/.rvm/scripts/rvm` állítja be a megfelelő környezeti változókat és aktiválja az alapértelemezett gemset-et).

### Redmine telepítése

A Redmine legfrissebb stabil 2.6-os verziójának letöltése SVN-en keresztül történik Salt-on keresztül, aminek feltétele az SVN csomag fennlétele. Nincs különösebb Redmine specifikus beállítás, tulajdonképpen egy Rails alkalmazás beállításáról van szó.

#### Adatbáziskapcsolat beállítása

A `config/database.yml` -t a Salt-on kereszül kapja meg, amiben a production és development mód szerint vannak megadva az adatbázis kapcsolat adatai.
A Salt MySQL state-jei segítségével hozunk létre felhasználót, adatbázist és ezt a kettőt egymáshoz rendeljük.

#### Rake/Bundle task-ok

Mivel nem találtam egyszerű megoldást arra, hogy RVM környezeten belül hogyan lehet parancsokat végrehajtani, itt is kénytelen voltam shell script-et használni. Ez

* telepíti/letölti a szükséges gem-eket (bundle install)
* létrehozza az adatbázist development és production mode-ra (`rake db:create db:migrate`)
* generál titkosító kulcsot a cookie-knak

Ezzel lényegében van egy viszonylag működőképes Redmine-unk, `rails s` illetve a `RAILS_ENV=production rails s` futtatásával ki is próbálhatjuk fejlesztői és production módban.
Hogy kívülről is használható legyen, szükséges egy webszerver (Puma) és egy reverse proxy (nginx) telepítése.

### Puma

A Puma egy webszerver, amely segítségével Ruby webalkalmazásokat futtathatunk. Azért esett erre a választásom, mert ennek tünt az alternatívákhoz képest ennek tünt a beállítása a legkevésbé macerásnak.

* Első lépésként a Redmine Gemfile-jába kell felvenni a puma gem-et függőségként a `gem "puma"` sor hozzáadásával majd `bundle install`-lal feltelepíteni.
* Ezután egy `tmp/puma` könyvtárat kell létrehozni a pidfile-nak és a statefile-nak.
* Végül egy `config/puma.rb` fájlban megadjuk a tmp könyvtárunk helyét és meghatározzuk a reverse proxy-hoz való kapcsolódás módját (sima TCP kapcsolat, UNIX socket stb). Ebben a példában én TCP kapcsolatot válaszottam, amelynek beállíthatjuk a portját.

Ezzel az alkalmazás Puma-ra való felkészítése véget is ért, maga a Puma szolgáltatás beállítása maradt hátra.
A Puma Github oldalán elérhetők Ubuntu-specifikus Upstart config-ok, amivel a webalkalmazásokat szolgáltatásként vezérelhetjük.

* A két Puma Upstart config-ot (puma.conf és puma-manager.conf)bemásoljuk az `/etc/init`-be
* A puma.conf-ban a `setuid`/`setguid` sorokban megadjuk, hogy milyen felhasználóként fusson
* Az `/etc/puma.conf` -ban egymás után felsoroljuk a webalkalmazások könyvtárait.

### Nginx

Végezetül szükséges a reverse proxy beállítása, amely segítségével kívülről érhetjük el a Redmine-t. Az nginx-re szinten egyszerű konfigurálhatósága miatt esett választásom.

* az `/etc/nginx/sites-enabled/`-ből töröljük az alapértelmezett oldalra mutató symlink-et
* Salt-on keresztül felmásoljuk az oldal config sablonját az `/etc/nginx/sites-available`-be, amelyben megadjuk a futó alkalmazás elérhetőségét
* a kapott konfig fájlunkról symlink-et készítünk a sites-enabled-be

Így szerverünk újraindítása után a megfelelő oldalra ellátogatva futó Redmine-t kapunk.

# Beállítások

## Redmine pillar

* `rvm_user`: Az a user, akinek az RVM-et telepíteni akarjuk
* `redmine_dir`: A Redmine telepítési könyvtára
* `redmine_db_name_prod`: Production adatbázis neve
* `redmine_db_name_dev`: Fejlesztő adatbázis neve
* `redmine_db_user`: Adatbázis felhasználó
* `redmine_db_pw`: Adatbázis jelszó
* `puma_user`: Milyen felhasználóként fusson a Puma
* `redmine_port`: Milyen porton fusson a Puma a helyi gépen
* `redmine_url`: (deprecated)
* `redmine_name`: Az nginx config-ban mi legyen az upstream neve
* `nginx_port`: Melyik porton fusson az nginx

## Extraservices pillar

* `wants_sshd`: Telepítve legyen-e az OpenSSH
* `wants_vsftpd`: Telepítve legyen-e a VsFTPD
* `wants_ping`: Ping engedélyezve legyen-e

# Használat

A következő state-ket írtam:

* `rvm`: Feltelepíti magát a Redmine-t
* `extraservices`: Feltelepíti az OpenSSH-t és a VsFTPD-t és beállítja a tűzfalat

Igen, ez egyátalán nem logikus, de nem merek hozzányúlni.

# Források

Tűzfal: <http://blog.bobbyallen.me/2012/08/23/configuring-iptables-for-a-ubuntu-12-04-web-server/>
Előfordított Ruby-k: <https://github.com/wayneeseguin/rvm/blob/master/config/remote>
Rails, Puma, nginx: <http://ruby-journal.com/how-to-setup-rails-app-with-puma-and-nginx/>
Redmine, Puma(ez valami unortodox init scriptet használ): <https://blog.rudeotter.com/install-redmine-with-nginx-puma-and-mariadbmysql-on-ubuntu-14-04/>
Puma, Ubuntu: <https://github.com/puma/puma/tree/master/tools/jungle/upstart>
Előfordított Ruby: <http://syntaxi.net/2012/12/21/installing-binaries-in-rvm/>

(In case any of you folks from above somehow manage to end up here: this is for homework in which I had to find a way to deploy Redmine using Salt Stack. Thanks for the guides, I owe all of you a beer!)