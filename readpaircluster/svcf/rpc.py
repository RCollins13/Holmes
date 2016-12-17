#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright © 2015 Matthew Stone <mstone5@mgh.harvard.edu>
# Distributed under terms of the MIT license.

"""

"""

# from svcf import SVFile
from collections import deque
from itertools import combinations
import networkx as nx


def is_smaller_chrom(chrA, chrB, le=True):
    """ Test if chrA is """

    if chrA.startswith('chr'):
        chrA = chrA[3:]
    if chrB.startswith('chr'):
        chrB = chrB[3:]

    # Numeric comparison, if possible
    if chrA.isdigit() and chrB.isdigit():
        if le:
            return int(chrA) <= int(chrB)
        else:
            return int(chrA) < int(chrB)

    # String comparison for X/Y
    elif not chrA.isdigit() and not chrB.isdigit():
        if le:
            return chrA <= chrB
        else:
            return chrA < chrB

    # Numeric is always less than X/Y
    else:
        return chrA.isdigit()


class RPCNode(object):
    def __init__(self, chrA, posA, chrB, posB, name='.'):
        """
        Common format for SV calls for intersection analyses.

        Includes methods for RPC-based clustering
        """
        self.chrA = str(chrA)
        self.posA = int(posA)
        self.chrB = str(chrB)
        self.posB = int(posB)
        self.name = str(name)

        self.sort_positions()

    def sort_positions(self):
        # Force chrA, posA to be upstream of chrB, posB
        if self.chrA == self.chrB:
            self.posA, self.posB = sorted([self.posA, self.posB])

        elif not is_smaller_chrom(self.chrA, self.chrB):
            self.chrA, self.chrB = self.chrB, self.chrA
            self.posA, self.posB = self.posB, self.posA

    def is_clusterable_with(self, other, dist):
        """
        Test if
        """
        return (self.chrA == other.chrA and
                abs(self.posA - other.posA) < dist)

    def clusters_with(self, other, dist):
        return (self.chrB == other.chrB and
                abs(self.posA - other.posA) < dist and
                abs(self.posB - other.posB) < dist)

    def is_in(self, tabixfile):
        """
        Test if breakpoints of SV fall into any region in tabix-indexed bed.

        Parameters
        ----------
        tabixfile : pysam.TabixFile

        Returns
        -------
        is_in : bool
        """

        return ((self.chrA.encode('utf-8') in tabixfile.contigs and
                 any(tabixfile.fetch(self.chrA, self.posA, self.posA + 1))) or
                (self.chrB.encode('utf-8') in tabixfile.contigs and
                 any(tabixfile.fetch(self.chrB, self.posB, self.posB + 1))))

    @property
    def HQ(self):
        """
        Filter function
        """
        return True

    @property
    def secondary(self):
        """
        Filter function
        TODO: rename
        """
        return False

    @property
    def is_allowed_chrom(self):
        GRCh = [str(x) for x in range(1, 23)] + 'X Y'.split()
        UCSC = ['chr' + x for x in GRCh]
        chroms = GRCh + UCSC

        return (self.chrA in chroms) and (self.chrB in chroms)

    def __hash__(self):
        return id(self)

    def __eq__(self, other):
        return (self.chrA == other.chrA and
                self.posA == other.posA and
                self.chrB == other.chrB and
                self.posB == other.posB and
                self.name == other.name)

    def _compare(self, other, le=True, match_chrom=False):
        """
        Abstraction for __le__ and __lt__

        Both use same logic for chromosome comparison
        """
        if match_chrom:
            if self.chrA == other.chrA:
                if self.chrB == other.chrB:
                    if le:
                        return self.posA <= other.posA
                    else:
                        return self.posA < other.posA
                else:
                    return is_smaller_chrom(self.chrB, other.chrB)
            else:
                return is_smaller_chrom(self.chrA, other.chrA)
        else:
            if self.chrA == other.chrA:
                if le:
                    return self.posA <= other.posA
                else:
                    return self.posA < other.posA
            else:
                return is_smaller_chrom(self.chrA, other.chrA)

    def __lt__(self, other):
        return self._compare(other, le=False)

    def __le__(self, other):
        return self._compare(other)

    def __str__(self):
        return ('{chrA}\t{posA}\t{posB}\t{chrA}\t{name}'.format(
                **self.__dict__))


class RPC(object):
    def __init__(self, nodes, dist, size=1, excluded_regions=None):
        """
        Parameters
        ----------
        svcalls : SVCalls
            Iterator over sorted SVCalls.
        dist : int
            Maximum clustering distance.
        excluded_regions : pysam.TabixFile, optional
            Regions to exclude from clustering. Any read pair that overlaps
            with a region is omitted.
        """

        self.nodes = nodes
        self.dist = dist
        self.size = size
        self.excluded_regions = excluded_regions

    # TODO: redefine rpc funcs as class to sublcass for rpc?
    # (inc mapq, size, etc)
    def get_candidates(self):
        """
        Find batches of SVCalls eligible for clustering.

        Requires input sorted by chromosome and position of first read in each
        pair. Pairs are collected while the first read in the next pair in the
        parser is within the maximum clustering distance of the first read of
        the previous pair.

        Yields
        ------
        deque of SVCalls
        """

        candidates = deque()
        prev = None

        self.excluded_count = 0
        self.total_count = 0
        for node in self.nodes:
            self.total_count += 1

            if (self.excluded_regions and node.is_in(self.excluded_regions)):
                self.excluded_count += 1
                continue

            if prev is None or prev.is_clusterable_with(node, self.dist):
                candidates.append(node)

            else:
                yield candidates
                candidates = deque([node])

            prev = node

        yield candidates

    def cluster(self):
        """
        Perform single linkage clustering on a batch of SVCalls.

        Yields
        ------
        list of RPCNode
            A cluster of read pairs.
        """

        for candidates in self.get_candidates():
            G = nx.Graph()

            # Permit clusters of size 1
            for node in candidates:
                G.add_node(node)

            for node1, node2 in combinations(candidates, 2):
                if node1.clusters_with(node2, self.dist):
                    G.add_edge(node1, node2)
            clusters = list(nx.connected_components(G))

            # Sort clusters internally by first read's position,
            # then sort clusters by first pair's first read's position
            clusters = [sorted(cluster, key=lambda v: (v.posA, v.name))
                        for cluster in clusters]
            clusters = sorted(clusters, key=lambda c: c[0].posA)

            for cluster in clusters:
                if len(cluster) >= self.size:
                    yield cluster


#  class SVCluster(RPC):
    #  def __init__(self, svfiles, dist, excluded_regions=None):
        #  nodes = heapq.merge(*svfiles)
        #  super().__init__(nodes, dist, excluded_regions)

    #  def merge_cluster(self):
        #  for cluster in self.cluster():
            #  yield SVCallCluster(cluster)
            #  pass

#  def svcluster(svfiles, dist):
    #  svcalls = heapq.merge(*svfiles)
    #  for cluster in rpc(svcalls, dist):
        #  if len(cluster) == 1:
            #  yield cluster[0]
        #  else:
            #  yield cluster[0].merge(cluster[1:])


#  def main():
    #  parser = argparse.ArgumentParser(
        #  description="")
    #  parser.add_argument('filelist')
    #  parser.add_argument('svcf')
    #  args = parser.parse_args()

    #  svcluster()


#  if __name__ == '__main__':
    #  main()
