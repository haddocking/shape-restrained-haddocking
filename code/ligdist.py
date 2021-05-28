#!/usr/bin/env python

"""
Computes the distance between a ligand and its cognate receptor.

Usage:
    python ligdist.py -lig <ligand id> <pdb file>

Example:
    # Will try to identify the compound in the PDB file automatically
    # and compute distances. Failing that it will list the identified
    # non-standard residues and prompt for the alternative mode.
    python ligdist.py 3eml.pdb

    # Alternative mode
    python ligdist.py -lig ZMA 3eml.pdb
"""

__version__ = '0.2.0'
__author__ = 'Panagiotis Koukos'
__email__ = 'p.koukos@uu.nl'

import argparse
from sys import exit, stdout
from collections import namedtuple
from itertools import groupby


def _check_args():
    """Constructs and sanity-checks the command-line arguments"""
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        '-v',
        '--verbose',
        default=False,
        action='store_true',
        required=False,
        help='Be more talkative'
    )
    parser.add_argument(
        '-V',
        '--version',
        action='version',
        version='%(prog)s {}'.format(__version__),
        help='Print the version and exit'
    )
    parser.add_argument(
        '-lig',
        required=False,
        nargs='?',
        help='Specify the residue ID of the ligand'
    )
    parser.add_argument(
        '-out',
        required=False,
        nargs='?',
        help='Path to output file. STDOUT by default'
    )
    parser.add_argument(
        '-format',
        required=False,
        choices=('res', 'atom'),
        default='res',
        nargs='?',
        help='Print atomic or residue (default) contacts'
    )
    parser.add_argument(
        '-cutoff',
        required=False,
        nargs='?',
        type=float,
        default=5.0,
        help='Specify the distance cutoff to use'
    )
    parser.add_argument(
        'input_file',
        help='Path to the input file'
    )

    args = parser.parse_args()
    return(args)


def extract_residues_from_input_file(input_file):
    """Parses the input file to extract atoms"""
    allowed_records = ('ATOM', 'HETATM')

    receptor_atoms = []
    ligand_atoms = []

    standard_residues = (
        'ALA', 'ARG', 'ASN', 'ASP', 'CYS',
        'GLN', 'GLU', 'GLY', 'HIS', 'ILE',
        'LEU', 'LYS', 'MET', 'PHE', 'PRO',
        'SER', 'THR', 'TRP', 'TYR', 'VAL',
        'MSE',
    )

    Atom = namedtuple('atom', 'chain resname resid icode name x y z')

    with open(input_file)as in_file:
        for line in in_file:
            if line.startswith(allowed_records):
                name = line[12:16]
                resname = line[17:20]
                resid = int(line[22:26].strip())
                icode = line[26]
                chain = line[21]
                x = float(line[30:38])
                y = float(line[38:46])
                z = float(line[46:54])
                atom = Atom(chain, resname, resid, icode, name, x, y, z)
                if resname in standard_residues:
                    receptor_atoms.append(atom)
                else:
                    ligand_atoms.append(atom)

    return [receptor_atoms, ligand_atoms]


def extract_residue_counts_from_atoms(ligand_atoms):
    """Extracts lists of residues from the parsed atoms"""
    common_hetatm = set([
        'HOH', 'SO4', 'PO4', 'GOL', 'EDO',
        'DMS', ' ZN', ' MG', ' NA', ' CL',
    ])

    ligand_residues = {_.resname for _ in ligand_atoms}

    unique_residues = ligand_residues.difference(common_hetatm)
    unique_residue_resids = {}

    for atom in ligand_atoms:
        if atom.resname not in unique_residues:
            continue
        if atom.resname not in unique_residue_resids:
            unique_residue_resids[atom.resname] = set()
        unique_residue_resids[atom.resname].add(atom.resid)
    
    unique_residue_counts = {
        _: len(unique_residue_resids[_]) for _ in unique_residue_resids
    }

    return unique_residue_counts


def identify_target_ligand(ligand_residues):
    """Attempts to guess the target ligand"""
    # If there is only one target ligand then that must be the target
    # even if there are multiple instances. That could be the case if
    # the compound is peptidic for example.
    if len(ligand_residues) == 1:
        return list(ligand_residues.keys())[0]
    
    # Alternatively, if there are multiple ligands count them and if
    # one is found to only have one instance use that after printing
    # a relevant message
    indeces = [ligand_residues[_] == 1 for _ in ligand_residues]
    if indeces.count(True) == 1:
        index = list(ligand_residues.values()).index(1)
        return list(ligand_residues.keys())[index]
    else:
        return None


def calc_atomic_contacts(receptor_atoms, ligand_atoms, target_ligand,
                         cutoff=5.0):
    """Calculates the 3D euclidean distance between ligand and receptor"""
    ligand_atoms = [_ for _ in ligand_atoms if _.resname == target_ligand]

    if len(ligand_atoms) == 0:
        raise RuntimeError(": no instances of ligand {} in input".format(
            target_ligand
        ))

    Contact = namedtuple(
        'contact',
        (
            'receptor_chain receptor_resid receptor_icode receptor_atom receptor_res'
            ' ligand_chain ligand_resid ligand_icode ligand_atom ligand_res distance'
        )
    )

    contacts = []

    for r_atom in receptor_atoms:
        for l_atom in ligand_atoms:
            dist = (
                (r_atom.x - l_atom.x) ** 2
                + (r_atom.y - l_atom.y) ** 2
                + (r_atom.z - l_atom.z) ** 2
            ) ** 0.5

            if dist <= cutoff:
                contacts.append(
                    Contact(
                        r_atom.chain,
                        r_atom.resid,
                        r_atom.icode,
                        r_atom.name,
                        r_atom.resname,
                        l_atom.chain,
                        l_atom.resid,
                        l_atom.icode,
                        l_atom.name,
                        l_atom.resname,
                        dist
                    )
                )

    return contacts


def calc_residue_contacts(contacts):
    """Extract the contacted residues from the atomic contacts"""
    def keyfunc(s):
        # Stolen from https://stackoverflow.com/a/16956262
        return [
            int(''.join(g)) if k
            else ''.join(g)
            for k, g in groupby('\0'+s, str.isdigit)
        ]

    receptor_residues = {
        str(_.receptor_resid) + _.receptor_icode.strip() for _ in contacts
    }

    return sorted(receptor_residues, key=keyfunc)


def main():
    """Runs the command-line script"""
    args = _check_args()

    if args.verbose is True:
        print("Running in verbose mode (-v).")
        print("Processing the input file...", end='')

    receptor_atoms, ligand_atoms = extract_residues_from_input_file(
        args.input_file
    )

    if args.verbose is True:
        print(' done.')

    if args.lig is not None:
        target_ligand = args.lig
    else:
        if args.verbose is True:
            print("Extracting residues from atoms...", end='')

        ligand_residues = extract_residue_counts_from_atoms(ligand_atoms)

        if args.verbose is True:
            print(' done.')
            print('Identifying unique ligand residues...', end='')
            print(' done.\n')
            print('Unique ligand residues, instances:')
            for key, value in ligand_residues.items():
                print('   {}\t{:3d}'.format(key, value))

        target_ligand = identify_target_ligand(ligand_residues)

        if target_ligand is None:
            if args.verbose is True:
                print()
                print(
                    'More than one unique ligand residues with ',
                    'multiple instances detected. Rerun with -lig.',
                    sep='\n'
                )
            else:
                print(
                    'More than one unique ligand residues with ',
                    'multiple instances detected:',
                    sep='\n'
                )
                for key, value in ligand_residues.items():
                    print('   {}\t{:3d}'.format(key, value))
                print('Rerun with -lig.')
            exit(1)

    if args.verbose is True:
        print()
        print(
            'Calculating atomic distances between receptor',
            'and ligand {} at a distance cutoff of {}Å.'.format(
                target_ligand,
                args.cutoff
            ), sep='\n'
        )
    
    atomic_contacts = calc_atomic_contacts(
        receptor_atoms,
        ligand_atoms,
        target_ligand,
        args.cutoff
    )

    residue_contacts = calc_residue_contacts(atomic_contacts)

    fh = open(args.out, 'w') if args.out is not None else stdout

    if args.format == 'atom':
        if args.out is None and args.verbose is True:
            print()
        for contact in atomic_contacts:
            print(
                "{:4d}{} {} {} {:4d}{} {} {} {:.3f}".format(
                    contact.receptor_resid,
                    contact.receptor_icode,
                    contact.receptor_chain,
                    contact.receptor_atom,
                    contact.ligand_resid,
                    contact.ligand_icode,
                    contact.ligand_chain,
                    contact.ligand_atom,
                    contact.distance
                ),
                file=fh
            )
    else:
        if args.out is None and args.verbose is True:
            print()
        for residue in residue_contacts:
            print(residue, file=fh)

    fh.close()

if __name__ == "__main__":
    main()
