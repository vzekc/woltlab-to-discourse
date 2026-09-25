# Geoinformation Field Migration Summary

## Current State

### Discourse (Target)
- **Field exists**: `user_field_21` named "Geoinformation" (imported from WoltLab option47)
- **Data status**: Empty - 0 users have any data
- **Storage**: `user_custom_fields` table with `name = 'Geoinformation'` or `name = 'user_field_21'`

### WoltLab MySQL (Source)
- **Table**: `wcf3_user_option_value`
- **Column**: `userOption47` (text)
- **Users with data**: 72

## Data Format

The Geoinformation field contains geo coordinates in various formats:

| Format | Count | Example |
|--------|-------|---------|
| `geo:lat,lng?z=zoom` | Most common | `geo:52.535150,13.394236?z=19` |
| `geo:lat,lng` (no zoom) | Several | `geo:50.800411,6.914046` |
| Raw `lat,lng` | Few | `50.554224,9.676251` |
| Multiple locations | Some | `geo:48.886...9.126... geo:48.774...9.239...` |
| OpenStreetMap URL | 2 | `https://www.openstreetmap.org/?#map=19/52.129158/11.604304` |

## Source Data Query

```sql
-- Get all users with Geoinformation from WoltLab
SELECT
  u.userID,
  u.username,
  v.userOption47 as geoinformation
FROM wcf3_user_option_value v
JOIN wcf3_user u ON v.userID = u.userID
WHERE LENGTH(v.userOption47) > 0
ORDER BY u.username;
```

## Users with Geoinformation (72 total)

| Username | Geoinformation |
|----------|----------------|
| abrandt | `geo:50.865919,7.048856?z=19` |
| Antikythera | `geo:48.88620265079618,9.126730596130201 geo:48.77454082475526,9.239136104221663 geo:48.744855,9.106896` |
| Arkadiusz | `geo:47.736996,8.967220?z=17` |
| back2BASIC | `geo:54.313439,10.130990 geo:48.140726,11.556963 geo:49.241191,6.990802` |
| bernd-7 | `geo:52.63255,7.10585?z=16` |
| berndb | `geo:49.280055,11.458531` |
| Bernhard | `geo:50.800411,6.914046` |
| Bobsi | `geo:50.362458,7.602040?z=17` |
| Buildi | `https://www.openstreetmap.org/?#map=19/52.129158/11.604304` |
| byteboard | `geo:50.01219,8.29712` |
| Cartouce | `https://www.openstreetmap.org/?#map=19/52.647010/7.094357` |
| Cebion | `50.554224,9.676251` |
| cha05e90 | `geo:52.726864,10.739920?z=19` |
| Claus77 | `geo:49.328707,11.019834?z=19` |
| clint | `geo:51.16204,6.79470?z=14` |
| Cobalt60 | `geo:52.03153,10.37993` |
| CPU Duke | `geo: 49.536401,8.350006` |
| detlef | `geo:50.706690,8.696891` |
| discmix | `geo:53.124716,10.212369?` |
| Ekatus | `geo:50.247242,8.309776` |
| eto | `geo:48.03482,11.95536` |
| fishermansfriendtoo | `geo:52.139388,8.145643?z=19` |
| flowerking | `geo:51.285602,6.368559?z=19` |
| for(;;) | `geo:51.043434,7.055757?z=19` |
| fritzeflink | `geo:51.68042035624528, 6.858695835761011` |
| FritzL | `geo:50.768104,6.072972` |
| funkenzupfer | `geo:51.281,6.245` |
| GePu | `geo:48.361179,11.559709?z=17` |
| Gerd5 | `geo:49.96977,8.05744` |
| gnupublic | `geo:52.49396,13.32539 geo:52.973054,12.991204` |
| hans | `geo:52.535150,13.394236?z=19 geo:53.84893,10.71431?z=16` |
| hix | `geo:48.04374,11.61882` |
| Jedi04 | `geo:52.46288,10.20068?z=16` |
| jobi23 | `geo:48.6338379,13.1880663?z=20` |
| Joe_IBM | `49.905705, 6.881174` |
| kkaempf | `geo:49.457881,11.075686?z=19` |
| klaly | `geo:49.478759,11.102782?z=18` |
| lemmi | `geo:49.386280,8.371469?z=19` |
| lost-bit | `geo:53.55831,9.72043?z=15` |
| Manawyrm | `geo:51.987044,9.823998?z=17` |
| MarkL | `geo:52.296551,11.423512` |
| Martin.W | `geo:49.469058,11.065373` |
| Matthias_7a7 | `geo:52.473998,13.309835?z=19` |
| MJGraf | `geo:48.273194,12.149581` |
| musterkonsument | `geo:48.241370,10.107913?z=18` |
| Norbert-97801 | `geo:50.804168,7.164321` |
| obbi | `geo:51.67195,7.08489?z=16` |
| olivetti | `geo:48.652218,9.572949?z=19` |
| Opal | `geo:52.486597,10.535159?z=19` |
| PC-Rath_de | `geo:51.376594,6.741609?z=19` |
| Plenz | `geo:51.32097,12.02577?z=16` |
| Prodatron | `geo:51.444553,6.660201?z=18` |
| Pyewacket | `geo:48.819707,9.269583?z=19` |
| Richi | `geo:48.431622,11.581693?z=19` |
| Sayjionix | `geo:48.153973,11.554417?z=19` |
| Scouter3D | `geo:48.514323,16.066557?z=19` |
| siralec | `geo:48.317205,11.661679 geo:49.794428,9.929350` |
| spacepilot3000 | `geo:53.097587,8.481789?z=17` |
| stiefkind | `geo:53.669692,14.186584` |
| Tassilo | `eo:51.937729,13.225773?z=19` (note: typo, missing 'g') |
| THein | `51.994216,7.560557?z=18` |
| Torkum73 | `geo:53.616463,9.867345` |
| TurboRadler | `geo: 49.566287,8.164616?z=19` (note: space after colon) |
| tuti | `geo:54.074002,9.984258?z=19` |
| Undefiniert | `geo:53.544957,9.970473?z=19` |
| vinesjedi | `geo:50.960604,6.902496?z=18` |
| Wir3dBrain | `geo:47.779496,12.451583?z=19` |
| x1541 | `geo:48.825659,9.307909` |
| XAct | `geo:48.725164,8.793575?z=19` |
| yalsi | `geo:52.34132,9.35572?z=13` |
| zac | `geo:48.940409,8.404444` |

## Migration Implementation Notes

### User Matching
- Match WoltLab `wcf3_user.username` to Discourse `users.username`
- Alternative: Use existing `import_id` custom field which stores the WoltLab userID

### Target Storage
```ruby
# In Discourse, store as user custom field
user.custom_fields['Geoinformation'] = geoinformation_value
user.save_custom_fields
```

### Data Cleaning Considerations
1. **Typos**: `eo:51.937...` should be `geo:51.937...` (Tassilo)
2. **Extra spaces**: `geo: 49.536...` has space after colon (CPU Duke, TurboRadler)
3. **Trailing characters**: `geo:53.124716,10.212369?` has trailing `?` (discmix)
4. **OSM URLs**: Convert to geo: format or keep as-is?

### Related Fields
- **Adresse für Marktplatz** (user_field_20): 277 users have real addresses (not placeholder text)
- Could be used together with Geoinformation for a member map feature
