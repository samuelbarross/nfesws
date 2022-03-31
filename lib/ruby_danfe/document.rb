module RubyDanfe
  class Document
	def ibarcode(h, w, x, y, info)
	  #fix tamanho barcode
	  x += 0.25
	  xdim = 0.95
	  Barby::Code128C.new(info).annotate_pdf(self, :x => x.cm, :y => Helper.invert(y.cm), :width => w.cm, :height => h.cm, :xdim => xdim) if info != ''
	end
  end
end