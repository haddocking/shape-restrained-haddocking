#!/usr/bin/env python

import os
import sys
import argparse
from collections import namedtuple


def __ions():
    """This construct simply contains the ions that we are looking for."""
    ions = set([
        "  K", " NA", " CA", "CL", " MG", " ZN", " MN", " NI", " YB"
    ])

    # Also add the HADDOCK format of the common ones to automatically
    # detect them without resid specification
    ions.update((
        " K1", "NA1", "CA2", "CL1", "MG2", "ZN2", "MN2", "MN3", "NI2",
        "YB2", "YB3"
    ))

    return ions


def _parse_arguments():
    """Parse the command-line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-r',
        '--resid',
        nargs='+',
        required=False,
        type=int,
        help=(
            'Residue index for the ion(s) of interest. Disables automatic '
            'mode if specified. Disabled by default. For multiple residues'
            ' separate residue numbers by whitespace. ie ./restrain_ion.py'
            ' -n 100 101 XXXX.pdb'
        ),
    )
    parser.add_argument(
        '-c',
        '--cutoff',
        nargs='?',
        default=4.0,
        required=False,
        type=float,
        help=(
            'Distance cutoff for the detection of residues close to the'
            'ion(s). 5A by default.'
        ),
    )
    parser.add_argument(
        '-l',
        '--loose',
        action='store_true',
        required=False,
        help=(
            'Loose settings for the contact filtering. By default only '
            'contacts with protein atoms will be considered. This means'
            ' that any adjacent ions or cofactors will be excluded. Since'
            ' this may or may not be what you want making use of this flag'
            ' will not exclude any atoms.'
        ),
    )
    parser.add_argument(
        '-i',
        '--input_file',
        nargs='?',
        required=False,
        default=sys.stdin,
        type=argparse.FileType('r'),
        help=('Path to the input PDB file. Defaults to STDIN'),
    )
    parser.add_argument(
        '-o',
        '--output_file',
        nargs='?',
        required=False,
        default=sys.stdout,
        type=argparse.FileType('w'),
        help=('Path to the output file. Disabled by default'),
    )
    parser.add_argument(
        '-p',
        '--pml_file',
        nargs='?',
        required=False,
        type=argparse.FileType('w'),
        help=('Path to the output PML file. Disabled by default'),
    )

    args = parser.parse_args()

    return args


def _extract_atom(line):
    """Extract atom data from an ATOM/HETATM line."""
    Atom = namedtuple('atom', 'chain resname resid icode name x y z')

    name = line[12:16]
    resname = line[17:20]
    resid = int(line[22:26].strip())
    icode = line[26]
    chain = line[21]
    x = float(line[30:38])
    y = float(line[38:46])
    z = float(line[46:54])

    atom = Atom(chain, resname, resid, icode, name, x, y, z)

    return atom


def _get_contacts(all_atoms, ions, cutoff):
    """Identify the atoms closest to the ions and return them."""
    contacts = {}
    for ion in ions:
        contacts[ion.resid] = []
        for atom in all_atoms:
            dist = (
                (ion.x - atom.x) ** 2
                + (ion.y - atom.y) ** 2
                + (ion.z - atom.z) ** 2
            ) ** 0.5
            if dist <= cutoff and ion.resname != atom.resname:
                contacts[ion.resid].append((atom, dist))

    return contacts


def _filter_contacts(ions, contacts, loose):
    """
    Filter the precalculated contacts to ensure they make sense

    Specifically:
        Sort the contacts by distance and then by residue and if possible
        include at most 1 atom per residue and at most 4 residues so max
        4 contacts per ion.
        If using strict settings (default - as opposed to loose) then only
        contacts with protein atoms will be considered. If not, then all
        atoms will be included.
    """
    standard_residues = (
        'ALA', 'ARG', 'ASN', 'ASP', 'CYS',
        'GLN', 'GLU', 'GLY', 'HIS', 'ILE',
        'LEU', 'LYS', 'MET', 'PHE', 'PRO',
        'SER', 'THR', 'TRP', 'TYR', 'VAL',
        'MSE',
    )

    filtered_contacts = {}
    for ion in ions:
        filtered_contacts[ion.resid] = []

        ion_contacts = contacts[ion.resid]
        ion_contacts = sorted(ion_contacts, key = lambda x: float(x[1]))

        for ion_contact in ion_contacts:
            atom, dist = ion_contact
            if atom.resname not in standard_residues and not loose:
                continue
            if atom.resid not in [_[0].resid for _ in filtered_contacts[ion.resid]]:
                filtered_contacts[ion.resid].append(ion_contact)
            if len(filtered_contacts[ion.resid]) == 4:
                break

    return filtered_contacts


def _format_and_print(ions, filtered_contacts, output_file, pml):
    """Format the filtered contacts and print them."""
    output_file.write(f"! Ion restraints{os.linesep}")
    for ion in ions:
        contacts = filtered_contacts[ion.resid]
        for contact in contacts:
            atom, dist = contact

            # Note the "" in the atom name for the second bracket. This is
            # there in case -l/--loose flag is activated which will allow
            # any ions in the vicinity of the ion of itnerest to be part of
            # restrains. Should these ions be formatted for HADDOCK (ZN+2),
            # then they need to be in "" to be correctly parsed by CNS.
            output_file.write(
                f'assi (segid {ion.chain} and resid {ion.resid}) '
                f'(segid {atom.chain} and resid {atom.resid} and name "{atom.name.strip()}") '
                f'{dist:.2f} 0.1 0.1{os.linesep}'
            )


def main():
    """Do all the things."""
    args = _parse_arguments()

    allowed_ions = __ions()
    allowed_records = ("ATOM", "HETATM")

    lines = args.input_file.readlines()

    atoms = list(map(
        _extract_atom, [_ for _ in lines if _.startswith(allowed_records)]
    ))

    args.input_file.close()

    ions = {_.resname for _ in atoms}.intersection(allowed_ions)
    ions = [_ for _ in atoms if _.resname in ions]

    contacts = _get_contacts(atoms, ions, args.cutoff)
    filtered_contacts = _filter_contacts(ions, contacts, args.loose)

    _format_and_print(ions, filtered_contacts, args.output_file, args.pml_file)

    args.output_file.close()

if __name__ == "__main__":
    main()
