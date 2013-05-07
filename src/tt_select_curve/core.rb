#-----------------------------------------------------------------------------
# Compatible: SketchUp 7 (PC)
#             (other versions untested)
#-----------------------------------------------------------------------------
#
# CHANGELOG
# 1.0.0 - 22.09.2010
#		 * Initial release.
#
#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'TT_Lib2/core.rb'

TT::Lib.compatible?('2.4.0', 'TT SelectCurve')

#-----------------------------------------------------------------------------

module TT::Plugins::SelectCurve  
  
  ### CONSTANTS ### --------------------------------------------------------
  
  VERSION = '1.0.0'
  
  
  ### MENU & TOOLBARS ### --------------------------------------------------
  
  unless file_loaded?( File.basename(__FILE__) )
    # Paths
    path = File.dirname( __FILE__ )
    res_path = File.join( path, 'TT_SelectCurve' )
    
    # Commands
    c_select_curve = UI::Command.new('Select Curve') { 
      self.select_curve_tool
    }
    c_select_curve.small_icon = File.join( res_path, 'select_curve_16.png' )
    c_select_curve.large_icon = File.join( res_path, 'select_curve_24.png' )
    c_select_curve.tooltip = 'Select Curves'
    c_select_curve.status_bar_text = 'Select sets of connected visible edges.'
    
    # Menus
    m = TT.menu('Tools')
    m.add_item( c_select_curve )
    
    #Toolbars
    toolbar = UI::Toolbar.new('Select Curve')
    toolbar = toolbar.add_item( c_select_curve )
    toolbar.show if toolbar.get_last_state == TB_VISIBLE
  end
  
  
  ### MAIN SCRIPT ### ------------------------------------------------------
  
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
  
  
  ### DEBUG ### ------------------------------------------------------------
  
  def self.reload
    load __FILE__
  end
  
end # module

#-----------------------------------------------------------------------------
file_loaded( File.basename(__FILE__) )
#-----------------------------------------------------------------------------