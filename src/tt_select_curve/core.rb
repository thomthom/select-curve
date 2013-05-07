#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'
begin
  require 'TT_Lib2/core.rb'
rescue LoadError => e
  module TT
    if @lib2_update.nil?
      url = 'http://www.thomthom.net/software/sketchup/tt_lib2/errors/not-installed'
      options = {
        :dialog_title => 'TT_Lib² Not Installed',
        :scrollable => false, :resizable => false, :left => 200, :top => 200
      }
      w = UI::WebDialog.new( options )
      w.set_size( 500, 300 )
      w.set_url( "#{url}?plugin=#{File.basename( __FILE__ )}" )
      w.show
      @lib2_update = w
    end
  end
end


#-------------------------------------------------------------------------------

if defined?( TT::Lib ) && TT::Lib.compatible?( '2.7.0', 'Select Curve' )

module TT::Plugins::SelectCurve  
  
  
  ### MENU & TOOLBARS ### ------------------------------------------------------
  
  unless file_loaded?( __FILE__ )   
    # Commands
    cmd = UI::Command.new('Select Curve') { 
      self.select_curve_tool
    }
    cmd.small_icon = File.join( PATH_ICONS, 'select_curve_16.png' )
    cmd.large_icon = File.join( PATH_ICONS, 'select_curve_24.png' )
    cmd.tooltip = 'Select Curves'
    cmd.status_bar_text = 'Select sets of connected visible edges.'
    c_select_curve = cmd
    
    # Menus
    m = TT.menu('Tools')
    m.add_item( c_select_curve )

    # Toolbar
    toolbar = UI::Toolbar.new( PLUGIN_NAME )
    toolbar.add_item( c_select_curve )
    unless toolbar.get_last_state == TB_HIDDEN
      toolbar.restore
      UI.start_timer( 0.1, false ) { toolbar.restore } # SU bug 2902434
    end
  end
  
  
  ### MAIN SCRIPT ### ----------------------------------------------------------
  
  def self.select_curve_tool
    Sketchup.active_model.tools.push_tool( SelectCurveTool.new(@settings) )
  end
  
  
  class SelectCurveTool
    
    def initialize(settings)
      @settings = settings
      
      @cursor_select        = TT::Cursor.get_id( :select )
      @cursor_select_add    = TT::Cursor.get_id( :select_add )
      @cursor_select_remove = TT::Cursor.get_id( :select_remove )
      @cursor_select_toggle = TT::Cursor.get_id( :select_toggle )
      
      @ctrl   = false
      @shift  = false
    end
    
    def activate
      updateUI()
    end
    
    def resume(view)
      updateUI()
    end
    
    def onLButtonUp(flags, x, y, view)
      ip = view.pick_helper
      ip.do_pick(x, y)
      e = ip.best_picked
      if e.is_a?( Sketchup::Edge ) && e.visible? && e.layer.visible? && !e.soft? 
        curve = find_curve( e )
      else
        curve = ( e.is_a?( Sketchup::Edge ) ) ? [e] : []
      end
      select_curve(curve)
    end
    
    def onKeyDown(key, repeat, flags, view)
      @ctrl  = true if key == COPY_MODIFIER_KEY
      @shift = true if key == CONSTRAIN_MODIFIER_KEY
      onSetCursor
    end
    
    def onKeyUp(key, repeat, flags, view)
      @ctrl  = false if key == COPY_MODIFIER_KEY
      @shift = false if key == CONSTRAIN_MODIFIER_KEY
      onSetCursor
    end
    
    def onSetCursor
      if @ctrl && @shift
        UI.set_cursor(@cursor_select_remove)
      elsif @ctrl
        UI.set_cursor(@cursor_select_add)
      elsif @shift
        UI.set_cursor(@cursor_select_toggle)
      else
        UI.set_cursor(@cursor_select)
      end
    end
    
    def updateUI
      Sketchup.status_text = "Pick an edge to select its visible connected edges."
    end
    
    def select_curve(curve)
      sel = Sketchup.active_model.selection
      if @ctrl && @shift
        sel.remove( curve )
      elsif @ctrl
        sel.add( curve )
      elsif @shift
        sel.toggle( curve )
      else
        sel.clear
        sel.add( curve )
      end
    end
    
    def find_curve(source_edge)
      curve = []
      stack = [ source_edge ]
      
      until stack.empty?
        edge = stack.shift
        curve << edge
        # Find connected edges
        valid_vertices = edge.vertices.select { |v|
          v.edges.reject { |e| e.soft? || e.hidden? || !e.layer.visible? }.size == 2
        }
        edges = valid_vertices.map { |v| v.edges }
        edges.flatten!
        edges.uniq!
        edges.reject! { |e| e.soft? || e.hidden? || !e.layer.visible? }
        edges = edges - curve
        stack += edges
      end
      curve
    end
    
  end # class SelectCurveTool
  
  
  ### DEBUG ### ----------------------------------------------------------------
  
  # @note Debug method to reload the plugin.
  #
  # @example
  #   TT::Plugins::Template.reload
  #
  # @param [Boolean] tt_lib Reloads TT_Lib2 if +true+.
  #
  # @return [Integer] Number of files reloaded.
  # @since 1.0.0
  def self.reload( tt_lib = false )
    original_verbose = $VERBOSE
    $VERBOSE = nil
    TT::Lib.reload if tt_lib
    # Core file (this)
    load __FILE__
    # Supporting files
    if defined?( PATH ) && File.exist?( PATH )
      x = Dir.glob( File.join(PATH, '*.{rb,rbs}') ).each { |file|
        load file
      }
      x.length + 1
    else
      1
    end
  ensure
    $VERBOSE = original_verbose
  end

end # module

end # if TT_Lib

#-------------------------------------------------------------------------------

file_loaded( __FILE__ )

#-------------------------------------------------------------------------------