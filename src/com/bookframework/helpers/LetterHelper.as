package com.bookframework.helpers
{
  import com.bookframework.config.BookConfig;
  import com.bookframework.models.BookHelveticaBold;
  import com.bookframework.views.modules.Letter;
  import com.bradwearsglasses.utils.helpers.NumberHelper;
  import com.bradwearsglasses.utils.helpers.StringHelper;
  
  import flash.display.Sprite;
  import flash.events.Event;
  
  import org.papervision3d.materials.special.MovieAssetParticleMaterial;
  import org.papervision3d.objects.DisplayObject3D;

  public class LetterHelper
  {
    
    public static var LINE_SPACE:Number = 16; 
    public static var helv:BookHelveticaBold = new BookHelveticaBold
    public static function place(...rest):Number {
      return place_array(rest)
    }

    public static function place_array(a:Array, scale:Number = 1):Number {
      var last_y:Number = 0, l:Letter, current_width:Number
      a.forEach(function(l:Letter, ...remainder):void {
          l.destination_scale = scale
          current_width = helv.widths[l.string]*l.destination_scale
          l.character.y = last_y + current_width/2   
          last_y+=current_width    
          l.character.scale = scale
        })      
      return last_y 
    }
    
    public static function reset(l:Letter):void { //reset x/y/z scale of letter
      l.character.scale       = .05;
      l.character.visible     = true;  
      l.character.x           = 0;
      l.character.y           = 0;
      l.character.z           = 0; 
      l.character.rotationY   = 0;
      l.character.rotationX   = 90
      l.character.rotationZ   = 90
    }

    public static function width(s:String):Number {
      return helv.widths[s]
    }
     
    public static function line(s:String, index:Number, a:Array, justify:Boolean=false, phrase:Array=null, text:DisplayObject3D=null, max_line_width:Number=0, prepopulated:Boolean=false):Number {
      
      var display:Array = StringHelper.trim(s).split("");
      var letters:Array = [];
      var erasures:Object = {};   
      var i:Number = -1, num_letters:Number = display.length, l:Letter
      var last_y:Number = -60
      var last_z:Number = 60
      var current_width:Number = 0
      var scale:Number = .15
      var line_width:Number = 280
      var last_line:Boolean = (index==(a.length-1))

      var text_width:Number = 0, skipped:Number=0, num_spaces:Number=0, k:String,
        erasable:Boolean=true; 
      while (++i < num_letters) {
    
        k = display[i]
        
        if (k=="[" && display[i+1]=="[") { //Starting bracket
          i++;
          erasable=false;
          skipped+=2
          continue;
        } else if (k=="]" && display[i+1]=="]") { //ending bracket
          i++;
          erasable=true;
          skipped+=2;
          continue;          
        }
        
        
        if (k !=" ") {
          text_width+=helv.widths[k]*scale
          if (erasable) {
            erasures[i-skipped] = 1;
          }
        } else {
          num_spaces++
        }
        
        letters.push(k)
      }
      
      if (text_width > max_line_width) max_line_width = text_width
      
      var space_size:Number = (text_width < line_width/BookConfig.LINE_JUSTIFICATION_TOLERANCE || !justify || last_line) ? helv.widths[" "]*scale : (line_width - text_width)/num_spaces
      
      if (last_line) last_y+= max_line_width - (text_width)
      
      //trace("\nWriting line:" + num_letters + "|" + prepopulated )
      num_letters-=skipped;
      i = -1;
      
      while (++i < num_letters) {
        if (!letters[i]) continue; //we don't have this letter. 
        l = (prepopulated) ? phrase[index][i] : new Letter(letters[i] as String)
        
        //reset positions -- we're primarily recycling them. 
        l.character.z = -200
        l.character.x = 40
        l.character.y = 40
        l.character.scaleX = 0.01;
        l.character.scaleY = 0.01;
        l.character.scaleZ = 0.01; 
        l.character.rotationX = 90; 
        l.character.rotationY = 0;
        l.character.rotationZ = 90; 
      
        l.erasable = (erasures[i])
        
        //set where we're going. 
        l.destination_scale=scale
        current_width = (l.string==" ") ? space_size : helv.widths[l.string]*l.destination_scale
        l.destination_y = last_y + current_width/2
        l.destination_z = -LINE_SPACE*index
        l.destination_x = l.character.x
        l.destination_rx = 90
        l.destination_ry = 0
        l.destination_rz = 90
        l.destination_alpha=1
        last_y+=current_width

        if (!prepopulated) {
          if (!phrase[index]) phrase[index] = []; 
          phrase[index].push(l);   
        }

        text.addChild(l.character)
        l.move_to();
      } 
      
      return max_line_width
      
    }      
       
    public static function exit(l:Letter, container:Sprite, on_complete:Function=null, outro:String  = 'explode'):void {
      if (!l || !container) return; 

      switch (outro) {
        case 'drop':
          l.destination_y     = 40
          l.destination_z     = -200
          l.destination_x     = 40
          l.destination_rx    = NumberHelper.random(-360,360)
          l.destination_ry    = NumberHelper.random(-360,360)
          l.destination_rz    =  NumberHelper.random(-360,360)
          l.destination_scale = 0
          l.destination_alpha = 1        
          break;
        case 'up':
          l.destination_y     = 40
          l.destination_x     = 40
          l.destination_z     = 400
          l.destination_rx    = l.character.rotationX
          l.destination_ry    = l.character.rotationY
          l.destination_rz    = l.character.rotationZ
          l.destination_scale = 0
          l.destination_alpha = 1          
          break  
        case 'explode':
        default:
          l.destination_y     = NumberHelper.random(-(container.stage.width*2)/2,(container.stage.width*4)/2)
          l.destination_x     = NumberHelper.random(-(container.stage.width*2)/2,(container.stage.width*4)/2)
          l.destination_z     = NumberHelper.random(-(container.stage.height*2)/2,(container.stage.height*4)/2)
          l.destination_rx    = NumberHelper.random(-360,360)
          l.destination_ry    = NumberHelper.random(-360,360)
          l.destination_rz    = NumberHelper.random(-360,360)
          l.destination_scale = NumberHelper.random(-1000,1000)/100
          l.destination_alpha = 1
          break;
        
      }
     
      if (on_complete !=null) l.addEventListener(Event.COMPLETE, on_complete);
      l.move_to()
    }

  }
}
