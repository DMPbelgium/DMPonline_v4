routes
======

Er bestaan, per organisatie, 3 routes, die enkel beschikbaar zijn via basic auth:

    https://dmponline.be/internal/exports/v01/organisations/:name/projects.json
    https://dmponline.be/internal/exports/v01/organisations/:name/updated_projects.json
    https://dmponline.be/internal/exports/v01/organisations/:name/deleted_projects.json

Voorbeelden:

    https://dmponline.be/internal/exports/v01/organisations/UGent/projects.json
    https://dmponline.be/internal/exports/v01/organisations/UGent/updated_projects.json
    https://dmponline.be/internal/exports/v01/organisations/UGent/deleted_projects.json


De `name` is de afgekorte naam van de organisatie

route "projects.json"
---------------------

* bevat alle (niet verwijderde) projecten op één bepaald ogenblik.

* is eigenlijk een (symbolische) link naar https://dmponline.be/internal/exports/v01/organisations/:name/:year/:month/projects_:utc.json

  vb. http://dmponline.be/internal/exports/v01/organisations/UGent/2020/02/projects_2020-02-09T19:00:10Z.json

* via het attribuut `links.self` zie je de canonieke url, die wél een datum bevat.

* elke avond om 20:00 wordt zo'n export gemaakt, en via "projects.json" kan je steeds aan de laatste nieuwe versie. Je ziet dus steeds de situatie zoals die gisterenavond was.

route "updated_projects.json"
-----------------------------

* bevat alle aangepaste projecten sinds de vorige export

* is eigenlijk een (symbolische) link naar https://dmponline.be/internal/exports/v01/organisations/:name/:year/:month/updated_projects_:utc.json

  vb. https://dmponline.be/internal/exports/v01/organisations/UGent/2020/02/updated_projects_2020-02-09T19:00:10Z.json

* via het attribuut `links.self` zie je de canonieke url, die wél een datum bevat.

* elke avond om 20:00 wordt zo'n export gemaakt, en via "updated_projects.json" kan je steeds aan de laatste nieuwe versie. Je ziet dus steeds de aanpassingen tussen gisteren en eergisteren.

route "deleted_projects.json"
-----------------------------

* bevat alle verwijderde projecten

* aangezien de data eigenlijk verwijderd is, beschikken we enkel over de "id" en de datum waarop dat verwijderd is.

* is eigenlijk een (symbolische) link naar https://dmponline.be/internal/exports/v01/organisations/:name/:year/:month/deleted_projects_:utc.json

  vb. https://dmponline.be/internal/exports/v01/organisations/UGent/2020/02/deleted_projects_2020-02-09T19:00:10Z.json

* elke avond om 20:00 wordt zo'n export gemaakt, en via "deleted_projects.json" kan je steeds aan de laatste nieuwe versie

* opgelet: deze informatie wordt nog niet zo bijgehouden. Dus er ontbreken mogelijks verwijderde projecten.

Formaat
=======

* output is steeds json, en volgt de json-api specificatie (https://jsonapi.org/format/#document-structure)

* output wordt verdeeld over meerdere pagina's. Via de attributen `links.prev` en `links.next` kan je navigeren tussen de pagina's
