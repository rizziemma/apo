#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""This python script reads its input file (csv)
   containing definitions of Petri nets classes and properties.
   It outputs files to be used by the webapp.
"""

##
## TODO:
##    - check that places mentioned in INPUTS and OUTPUTS actually exist.
##
## POSSIBLY:
#"    - add figures to illustrate definitions (examples and counter-examples)
##    - allow short names for places (to be used in INPUTS and OUTPUTS)
##  
##

import csv

##################################################################
##                        CONFIG
##
## Paths to the input and output files

SOURCEFILE = "properties.csv"
OUTPROPS   = "../src/resources/properties_ref.json"
OUTNET     = "../src/resources/properties_net.json"

## Headers of the columns of interest.
HEADERS = [
        ## Header : column name : column id
        
        ## Header 1, for places
        { "Type":"TYP", "Name":"PNAME", "AKA":"AKA", "Definition":"PDEF", "References":"PREF" } ,

        ## Header 2, for transitions
        { "Transition name":"TNAME", "Inputs":"TIN", "Outputs":"TOUT", "Definition":"TDEF", "References":"TREF" } ,
]

## Note that all lines do not have the same layout. The layout depends on the line type (place or transition)

## Each non-empty line of the input file is either :
##    - a header line (if it contains all the keywords of one of the headers, defined above)
##    - a data line otherwise
##
## Each data line is transformed into a dictionary mapping column id to the corresponding cell value.
##    e.g. { "TYP" : "P" , "PNAME" : "Safe" , "AKA" : "1-Bounded", "Definition" : "The amount of tokens in each place is bounded by 1." , ... }
##
###################################################################

## Detect empty lines
def cells_are_empty(cells):
        return all(v == "" for v in cells)

##
## Detect header lines
##

##
## Warning for functional people: map(fun, list)  builds a mutable iterator, which can be traversed only once.
##

## Returns none if the line is not a header.
## Otherwise, returns a mapping { column id => column number }
def contains_header(h,cells):
        result = {}
        cells = list(map(str.lower,cells))
        try:
                for name,id in h.items():
                        ## Find which cell contains name
                        num = cells.index(name.lower())
                        result[id] = num                        
                return result
        except ValueError:
                return None
                        
def is_header_line(cells):
        matched_headers = map(lambda h : contains_header(h,cells), HEADERS)
        return next(filter(None, matched_headers), None)

## Transforms a cell list into a dictionary, according to the given header.
def map_line(cells, header):
        return {k: cells[num] for k, num in header.items()}

##        
## START HERE
##

## Explain what we are doing and open source file.
print("\n This script generates files used by the webapp.\n")
print("  🢧  INPUT file: reading "+SOURCEFILE)

margin = "       "

source = open(SOURCEFILE, "r")

places=[]
transitions=[]

## Iterate over every line of the source file.
linenb = 0
current_header = {}

for data in csv.reader(source, quotechar='"', delimiter=',',
                       quoting=csv.QUOTE_ALL, skipinitialspace=True):
##for line in source:
        linenb += 1
##        data = line.strip("\n").split(";")
        data = list(map(str.strip,data))

        if not cells_are_empty(data) :
                head = is_header_line(data)
                if head:
                        print(margin + "Header found line #{:3d} : ".format(linenb) + str(head))
                        ## Merge this header with the current one.
                        current_header.update(head)
                else:
                        vline = map_line(data, current_header)
                        
                        ## Get line type
                        typ = vline["TYP"]

                        ## Python does not have a switch statement (no comment).
                        if typ == "":
                                pass
                        
                        elif typ == "P":
                                ## This is a place
                                places.append(vline)

                        elif typ == "T":
                                ## This is a transition
                                transitions.append(vline)

                        else:
                                print("Unknown type line " + str(linenb) + " : '" + str(typ) + "'" )
                
source.close()

print("")
print("  🔍 Found:")
print(margin + str(len(places)) + " places (properties or Petri net classes)")
print(margin + str(len(transitions)) + " transitions (inference rules)")
print("")


##
## Write dest files.
##
print("  🢦  OUTPUT files: writing " + OUTPROPS)
print("                       and " + OUTNET)
print("")
ref = open(OUTPROPS, "w")
ref.write('{"data":[')

net = open(OUTNET, "w")
net.write('.name "Properties"\n.type PPN\n')


outplaces = ""
outtransitions = ""
outflows = ""


first = True

for data in places :
        if not first :
                ref.write(',\n')

        place_id = data["PNAME"].replace(" ", "-")
                
        ref.write('{ "name":"'+ place_id +'",'
                  +'"aka":"' + data["AKA"] + '",'
                  +'"def":"' + data["PDEF"] + '",'
                  +'"ref":"' + data["PREF"] + '"}')
        first = False

        #net
        outplaces += place_id + "\n"

for data in transitions:
        ref.write(',\n')

        trans_id = data["TNAME"].replace(" ", "-")
        
        ref.write('{ "name":"' + trans_id + '",'
                  +'"def":"' + data["TDEF"] + '",'
                  +'"aka":"''",'
                  +'"ref":"' + data["TREF"] + '"}')

        outtransitions += trans_id + "\n"
        outflows += trans_id + ": {" + data["TIN"] + "} -> {" + data["TOUT"] + "}\n"

ref.write("] }")

net.write("\n.places\n"+outplaces)
net.write("\n.transitions\n"+outtransitions)
net.write("\n.flows\n"+outflows)

ref.write("\n")
net.write("\n")

ref.close()
net.close()

print("   ✓ Done.")
print("")
