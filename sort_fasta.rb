#!/usr/bin/env ruby
# frozen_string_literal: true

# usage: ruby sort_fasta.rb -o <id-tab-int> -f <FASTA> [ -l <length> ]

require 'gdbm'
require 'yaml'
require 'bio'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: sort_fasta.rb [options]'

  opts.on('-f FASTA', '--fasta FASTA', String, 'FASTA file')
  opts.on('-o TSV', '--order TSV', String, 'TSV file with sort order')
  opts.on('-l', '--length_cutoff LEN', Integer, 'Sequences > LEN bp will not be sorted')
  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!(into: options)

dbfile = 'seqstore.db'
gdb = GDBM.new(dbfile, nil, GDBM::NEWDB)

id_to_count = {}
File.open(options[:order]).each do |line|
  (id, count) = line.chomp.split
  id_to_count[id] = count.to_i
end

id_to_size = {}
Bio::FlatFile.open(Bio::FastaFormat, options[:fasta]) do |ff|
  ff.each do |entry|
    id_to_count[entry.entry_id] ||= 0
    id_to_count[entry.entry_id] = 0 if options[:length_cutoff] && entry.length > options[:length_cutoff]
    id_to_size[entry.entry_id] = entry.seq.size
    gdb[entry.entry_id] = entry.to_yaml
  end
end

gdb.keys.sort_by  do |e|
  [id_to_count[e], id_to_size[e]]
end.reverse.each  do |id|
  e = YAML.safe_load(gdb[id])
  puts e.seq.to_fasta(e.definition)
end

gdb.close
File.delete(dbfile)
