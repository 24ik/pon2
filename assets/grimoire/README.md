# Grimoire Data

Some data is sourced from the
[Nazo Puyo Grimoire Ver11.1](https://docs.google.com/spreadsheets/d/1nGQbpigyuJGF1x_pr5MVPBRYDp03EmVj/edit?usp=sharing&ouid=115973110803976465862&rtpof=true&sd=true).

## Adding Data

Problem data is managed by an index, so adding data requires following the proper
procedure.
Specifically, TOML files directly under the `grimoire` directory are sorted by their
names and used in order from the top.
Therefore, when adding data, **create a new file with an appropriate numerical prefix
added to the filename** and write the data into it.
