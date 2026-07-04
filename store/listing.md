# Play Store listing content

Everything to paste into Play Console → Store presence → Main store listing.
Assets in this folder: `play_icon_512.png` (App icon), `feature_graphic.png`
(Feature graphic). Screenshots: add at least 2 phone screenshots (see README
note at the bottom).

## App name (30 chars max)

    Offline MTG Card Search

(Avoid leading with "Scryfall" — it's their trademark. The description below
credits them properly.)

## Short description (80 chars max)

    Fast offline Magic: The Gathering card search with powerful filters.

## Full description (4000 chars max)

Search every Magic: The Gathering card — instantly, offline, anywhere.

Offline MTG Card Search puts the entire card catalog in your pocket. Download
the card database once, and every search after that runs entirely on your
device: no internet needed, no waiting, no ads.

**Powerful search**
• Full Scryfall search syntax: t:creature c:rg mv<=3, o:"enters tapped",
  pow>tou, and much more
• Tap-friendly filters: card name, types, rules text, colors, commander
  identity, mana value, format legality, rarity, and set
• Sort by name, mana value, release date, EDHREC rank, rarity, or power

**Built for deck building**
• Card pages with rulings, legalities, and every printing
• Flip double-faced cards
• Save cards to a list to come back to later (long-press any card)
• Set a default filter (e.g. your commander's color identity) applied on
  every launch

**Truly offline**
• Card database stored on-device and updated on your schedule
• Optional image pack: download one image per card (~3.3 GB) and the whole
  app works with no connection at all
• Without the pack, images load from the network and cards you've viewed
  stay cached

Card data and images are kindly provided by Scryfall (scryfall.com). This app
is unofficial Fan Content permitted under the Fan Content Policy. Not
approved/endorsed by Wizards. Portions of the materials used are property of
Wizards of the Coast. ™ & © Wizards of the Coast.

## Console form answers (quick reference)

- Category: Tools (or Entertainment)
- Ads: No ads
- Data safety: No data collected, no data shared
- Content rating questionnaire: reference/utility app → Everyone
- Privacy policy URL: https://<your-github-username>.github.io/scryfall-offline/privacy-policy.html
  (enable GitHub Pages: repo Settings → Pages → Deploy from branch → main,
  folder /docs — then fill in the contact email placeholder in
  docs/privacy-policy.html)

## Screenshots

Play requires at least 2 phone screenshots (PNG/JPEG, shortest side ≥320px).
Take them on your phone with the app running a good-looking state:

    flutter run --release
    # then for each screen you want:
    adb exec-out screencap -p > store/screenshot_1.png

Suggested set: search grid full of cards, the filter panel open over
results, a card detail page, the saved-cards screen.
