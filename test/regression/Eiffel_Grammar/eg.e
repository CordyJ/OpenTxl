indexing
   description: "Main gradient dialog window."
   status: "Free according to the GPL license (see COPYING)"
   date: "$Date$"
   revision: "$Revision$"
   author: "Mark Arrasmith <arrasmith@math.twsu.edu> and Miron Brezuleanu"
   

class GRADIENT_EDITOR
   
inherit
   NO_CLOSE_WINDOW
      redefine
	 make
      end
   GTK_COMMAND
   STARTUP
   
creation
   make
   
feature -- commands
   
   make is
	 -- will set up everything
      do
	 Precursor
	 set_title("Gradient - " + config.map_name)
	 build_vbox
	 add(vbox)
	 vbox.show
      end
   
   build_vbox is
      local
	 hbox: GTK_HBOX
	 svbox: GTK_VBOX
	 button: GTK_BUTTON
	 label: GTK_LABEL
	 sbutton: GTK_SPIN_BUTTON
      do
	 !!vbox.make(False, 0)
	 
	 !!hbox.make(False, 0)
	 
	 !!canvas.make
	 canvas.set_dialog(Current)
	 hbox.pack_start(canvas, False, False, 0)
	 canvas.show
	 
	 !!svbox.make(False, 0)

	 !!button.make_with_label("Redraw")
	 button.signal_connect("clicked", Current, "redraw")
	 svbox.pack_start(button, False, False, 0)
	 button.show
		 
	 !!button.make_with_label("Reset")
	 button.signal_connect("clicked", Current, "reset")
	 svbox.pack_start(button, False, False, 0)
	 button.show
	 	 
	 !!button.make_with_label("Load")
	 button.signal_connect("clicked", Current, "load")
	 svbox.pack_start(button, False, False, 0)
	 button.show
	 	 
	 !!button.make_with_label("Save")
	 button.signal_connect("clicked", Current, "save")
	 svbox.pack_start(button, False, False, 0)
	 button.show
	 	 
	 !!label.make_with_label("No. of colors")
	 svbox.pack_start(label, False, False, 0)
	 label.show
	 
	 !!num_colors_adj.make(config.colors.to_real, 
			       24.0, 64000.0, 1.0, 100.0, 0.0)
	 !!sbutton.make_with_adjustment(num_colors_adj, 0.5, 0)
	 num_colors_adj.signal_connect("value_changed", 
				       Current, "adj_change")
	 svbox.pack_start(sbutton, False, False, 0)
	 sbutton.show
	 
	 hbox.pack_start(svbox, False, False, 0)
	 svbox.show
	 
	 vbox.pack_start(hbox, False, False, 0)
	 hbox.show	 
      end
   
   execute(d: ANY) is
      local
	 s: STRING
      do
	 s ?= d
	 check
	    s /= Void
	 end
	 if equal(s, "reset") then
	    colors.reset
	    canvas.update
	 elseif equal(s, "redraw") then
	    efractal_canvas.generate
	 elseif equal(s, "load") then
	    colors.load
	    canvas.update
		if colors.filename /= Void then
		  config.set_map_name(colors.filename)
		end
	    set_title("Gradient - " + config.map_name)
	 elseif equal(s, "save") then
	    colors.save
		if colors.filename /= Void then
		  config.set_map_name(colors.filename)
		end
	    set_title("Gradient - " + config.map_name)
	 elseif equal(s, "adj_change") then
	    colors.set_num_colors(num_colors_adj.value.floor)
	    canvas.update
	 end
      end
   
feature -- attributes & queries
   
   canvas: GRADIENT_EDITOR_CANVAS
	 -- the canvas where the color selection is done
   
   vbox: GTK_VBOX
   num_colors_adj: GTK_ADJUSTMENT
   
end
	 
