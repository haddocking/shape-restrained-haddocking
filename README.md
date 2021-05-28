# Shape restrained haddocking

## Introduction

This repository contains all the code and data associated with our publication
titled:

"Shape-restrained modelling of protein-small molecule complexes with HADDOCK"

immediately available online as a preprint and peer-reviewed publication.

A secondary addendum to the publication is the sbgrid deposition which in addition
to the contents of this repository also contains all the models that were generated
for the benchmarking of these protocols and are impossible to include in GitHub due
to repository size limitations.

We have made our best efforts to organise the data as intuitively as possible so as
to make our code and data as assesible to as many interested parties as possible. An
explanation of the various folders and files in this repository follows.

## Data layout overview [[^](#shape-restrained-haddocking)]

This is the top-level git directory

```sh
LICENSE
README.md
code/
conformers/
data/
manuscript/
restraints/
runs/
scripts/
setup/
shapes/
structures/
templates/
toppar/
```

## Details [[^](#shape-restrained-haddocking)]

`LICENSE` contains the license under which we are making our code and data available.
`README.md` is this document.

### Code [[^](#shape-restrained-haddocking)]

---

This folder contains general-purpose scripts that can be applied beyond the
specific confines of this project. In most cases the name of the code should
suffice in terms of explanation as to what it does. In case it doesn't though,
most of these files are very well documented.

The contents of the folder are:

```sh
add_atom_features.py
add_his_protonation.py
calc_mcs.py*
dist_to_izone.py*
generate_conformers.py*
get_similar_by_ligand.py*
get_similar_by_protein.py*
ligdist.py*
pdb_element.py*
pharm2D_Tc.py
plot_helpers.R
restrain_ion.py*
```

In summary, `add_atom_features.py` can be used to define the features on which the
pharmacophore-based protocol depends on, `add_his_protonation.py` makes use of the
output of [`molprobity`](http://molprobity.biochem.duke.edu/) to set the protonation
state of HIS residues (this was only used for the pharmacophore-based protocol),
`calc_mcs.py` calculates the Maximum Common Substructure-based similarity between
a single reference and multiple template compounds using the Tanimoto and Tversky
coefficients (the latter was used for the shape-based protocol), `dist_to_izone.py`
converts atom-based distances as they are calculated by the `ligdist.py` script to
the format that is accepted [ProFit](http://www.bioinf.org.uk/software/profit/),
`generate_conformers.py` generates 3D conformers while accepting multiple arguments
that determine the process that is used for the torsional sampling, `get_similar_by_ligand.py`
and `get_similar_by_protein.py` were used to fetch data from the [RCSB](https://www.rcsb.org/)
while making use of the REST- and graphql-based APIs, `ligdist.py` calculates distances
between a compound and its cognate receptor, `pdb_element.py` is a modified version of
the repsective tool from the [PDB-tools suite](https://www.bonvinlab.org/pdb-tools/)
used for the analysis of the results, `pharm2D_Tc.py` calculates the Tanimoto
coeeficient between compounds using the aforementioned pharmacophore fingerprints,
`plot_helpers.R` is a `ggplot`-based library of graphs and plots and `restrain_ion.py`
produces tbl-formatted (accepted by HADDOCK) restraints that maintain the correct
geometry for ions and their coordinating sidechains throughout the simulation.

Details regarding the software requirements for this project can be found in a
[later](#software-requirements) section.

### Conformers [[^](#shape-restrained-haddocking)]

---

This is where individual PDB files for each target compound can be found. The
conformers have been generated with RDKit using the settings described in the
paper. There are at most 50 PDB files per directory as that is the number of
conformers that was found to provide the best balance of docking results and
sampling efficiency. Files are grouped by target.

### Data [[^](#shape-restrained-haddocking)]

---

This folder hosts two files, one per protocol and they are appropriately named as to
reflect the protocol to which they correspond. The file for the shape protocol is in
JSON format because of the presence of the `low_sim` templates whereas the file for
the pharm protocol is in csv format. These files contain all the data pertaining to
the targets, for example, template PDB ids, RMSD of the binding site, etc...

### Manuscript [[^](#shape-restrained-haddocking)]

---

This folder contains all the code, data and analysis that was undertaken in preparation
for the submission of the manuscript. Additionally it contains all the figures of the
main text as well as the tables and figures of the SI.

### Restraints [[^](#shape-restrained-haddocking)]

---

This is where the restraints used during the two protocols can be found. This is
broken down by protocol and grouped by target.

### Runs [[^](#shape-restrained-haddocking)]

---

This folder is not version-controlled since it would be impossible to have
the run folders under git and is therefore absent from the repository. It is the
default location for the runs created by the scripts under `scripts`.

### Scripts [[^](#shape-restrained-haddocking)]

---

Broken down by protocol, this is where the scripts that orchestrate setting up,
starting and analysing runs can be found. The names should be self-explanatory.
They all assume that the runs are in the aforementioned `runs` folder and the
run directories have already been created. The crontab that is running everything
looks something like this:

```sh
$ crontab -l
*/5 * * * * cd .../runs; ../scripts/shape/start.sh >> .start.log 2>> .start.err
*/1 * * * * cd .../runs; ../scripts/shape/analyse.sh >> .analyse.log 2>> .analyse.err
1,16,31,46 * * * * cd .../runs; ../scripts/shape/check.sh &> .check.log
```

where `...` is the path to the aforementioned `runs` directory.

### Setup [[^](#shape-restrained-haddocking)]

---

Broken down by protocol, this is where the `run.param` and `run.cns` used by the
scripts under `scripts` are located. These files control the protocol that is being
benchmarked.

### Shapes [[^](#shape-restrained-haddocking)]

---

Broken down by protocol, this is where the shapes extracted from the PDB files of
the templates can be found. For the shape protocol, some targets also contain the
low_sim shapes. **The shapes are in the coordinate system of their respective
template receptor, and by extension the reference as well.**

### Structures [[^](#shape-restrained-haddocking)]

---

These are the reference structures of the benchmark. In addition to the reference
complex each target folder also contains the reference compound, the original complex
as it was downloaded from the PDB and a README file detailing all the modifications
that were made in preparing the structure for docking/analysis.

### Templates [[^](#shape-restrained-haddocking)]

---

Broken down by protocol, this is where the template receptors and compounds (in
separate files) can be found. **The templates have been superimposed on their
respective reference receptor.**

### Toppar [[^](#shape-restrained-haddocking)]

---

This is where the topologies and parameters for all target compounds can
be found.

## Software requirements [[^](#shape-restrained-haddocking)]

Regarding the software side of things, the code that can be found in [scripts](scripts)
only depends on bash meaning there are no dependencies. The code under [code](code) is
mostly python and does have a few dependencies. Namely:

```sh
requests
pandas
rdkit
openbabel
```

along with a reasonably recent version of Python. This code and all work on this
project was performed with Python 3.8 installed managed by conda. Conda was chosen
as it is the preferred way to install RDKit. All of the aforementioned modules can
be found on the conda-forge channel and installed in one go with a command that looks
like this:

`conda install -c conda-forge requests pandas rkdit openbabel`
