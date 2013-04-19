$:.unshift "./"
require "narray"
include Math

class NArray
  def save(file_name, delim = " ")
    File.open(file_name, "w") do |file|
      file.puts "# shape: #{self.shape}"
      self.to_a.each_with_index do |a, j|
        if a.instance_of?(Array)
          a.each_with_index do |b, i|
            file.print "#{b}"
            file.print "#{delim}" if not i == a.size - 1
          end
        else
          file.print "#{a}"
          file.print "#{delim}" if not j == self.to_a.size - 1
        end
        file.print "\n"
      end
    end
  end

  def self.load(file, split = " ")
    mat = []
    File.open(file).each do |row|
      if row[0] != "#"
        r = row.split(split).map{|v| v.to_f}
        if not r.empty?
          val = r.size == 1 ? r[0].to_f : r
          mat << val
        end
      end
    end
    NArray.to_na(mat)
  end
end

class NMatrix
  def col(n)
    NVector.ref self[n, 0..-1].flatten
  end

  def row(n)
    NVector.ref self[0..-1, n].flatten
  end

  def divide(other)
    mat = self
    self.to_a.each_with_index do |row, i|
      row.each_with_index do |v, j|
        mat[j, i] = self[j, i] / other[j, i]
      end
    end
    NMatrix.to_na(mat)
  end
end

class NVector
  def in_exp
    self.collect{|v| exp(v)}
  end
end
