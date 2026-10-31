# force_policerepair

Free repair bay for FiveM. Police (or any job you configure) drive into the bay, open the repair menu and a
mechanic walks over and repairs the vehicle while an ox_lib progress bar runs. The menu can also show the engine
and body health.

- ESX Legacy, QBCore and QBox out of the box, other frameworks through `custom.lua`
- ox_target or qb-target, with an [E] + text UI fallback when neither runs
- Several bays, each with its own jobs, minimum grades, optional vehicle list and mechanic ped
- Checked on the server: job, grade, duty, that the player drives the vehicle, that the vehicle is in the bay,
  the repair time and a cooldown
- Cancel, death and a resource restart never leave the vehicle frozen
- English and Swedish locales

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- OneSync (on by default on current servers)

No database is used.

## Install

1. Put the folder in your resources as `force_policerepair`.
2. Add `ensure force_policerepair` to `server.cfg` below `ensure ox_lib`. The start order relative to your
   framework and target resource doesn't matter.
3. Edit `config.lua`: jobs, coordinates and the mechanic per bay.

## Documentation

https://docs.forcedevelopments.com/free-resources/force_policerepair/introduction

## More from Force Developments

Paid resources that pair well with this one. Escrow-protected, documented, with free updates:

- **[Force Invoices](https://forcedevelopments.com/scripts/force-invoices?utm_source=github&utm_medium=readme&utm_campaign=force_policerepair)**: personal and job billing.
- **[Force Phonetracking](https://forcedevelopments.com/scripts/force-phonetracking?utm_source=github&utm_medium=readme&utm_campaign=force_policerepair)**: trace player phones.

Want all of them? [All Resources](https://forcedevelopments.com/scripts/all-resources-1-month?utm_source=github&utm_medium=readme&utm_campaign=force_policerepair) is a monthly subscription that includes every paid resource. Browse the full catalogue at [forcedevelopments.com](https://forcedevelopments.com/scripts?utm_source=github&utm_medium=readme&utm_campaign=force_policerepair).

## License

Apache 2.0, see [LICENSE](LICENSE).
