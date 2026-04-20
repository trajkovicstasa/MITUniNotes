# UniNotes Test Checklist

Ovo je radna lista testova koje treba proveriti kada zavrsimo sledeci veci blok funkcionalnosti.

## Stabilni tokovi koji su vec prosli

- Admin dodavanje skripte u bazu
- Admin izmena skripte
- Cloudinary upload cover slike
- Cloudinary upload PDF fajla
- Prikaz odobrenih skripti u klijentskoj aplikaciji
- `Latest arrival` / `Najnovije beleske`
- Dodavanje u korpu
- Brisanje iz korpe pojedinacno
- Praznjenje cele korpe
- Wishlist dodavanje i brisanje
- Checkout i kreiranje `orders`
- Prikaz `All Orders`
- Profilna slika pri registraciji i naknadna izmena
- Free PDF preview unutar aplikacije
- Free PDF download
- Premium lock pre kupovine
- Premium unlock posle kupovine
- Korisnicko slanje skripte kao `pending`
- Admin odobravanje / odbijanje skripte
- `Moje poslate skripte`
- Recenzije i komentari iz Firestore-a
- Ogranicenje recenzija:
  - free skripte: svaki prijavljeni korisnik
  - premium skripte: samo korisnik koji je kupio

## Trenutno poslednje odradjeno i treba proveriti kada emulator bude stabilan

- Brisanje sopstvene recenzije sa detalja skripte
- Posle brisanja:
  - komentar nestaje iz liste
  - prosecna ocena se menja
  - broj recenzija se menja
  - forma se resetuje

## Sledeci testovi koje treba raditi za nove feature-e

- Ako dodamo admin moderaciju recenzija:
  - admin vidi sve recenzije
  - admin moze da ukloni neprimerenu recenziju
  - uklonjena recenzija nestaje iz klijenta

- Ako dodamo payment integraciju:
  - premium skripta ne moze da se otvori bez placanja
  - posle uspesnog placanja pristup se otkljucava
  - order ostaje upisan u bazi

- Ako dodamo dodatni UX polish:
  - pretraga ne baguje tokom kucanja
  - details ekran ne treperi pri premium access proveri
  - download i preview rade i posle restarta aplikacije

## Napomena

Dok emulator baguje, fokus je na implementaciji. Ovu listu koristimo kao izvor istine za kasnije sistematsko testiranje.
