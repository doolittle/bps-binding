package com.betweenpageandscreen.binding.helpers
{
  import com.betweenpageandscreen.binding.config.BookConfig;
  import com.betweenpageandscreen.binding.views.modules.Letter;
  import com.bradwearsglasses.utils.helpers.NumberHelper;
  import com.bradwearsglasses.utils.helpers.StringHelper;
  
  import flash.display.Sprite;
  import flash.events.Event;
  
  import org.libspark.betweenas3.core.easing.IEasing;
  import org.libspark.betweenas3.easing.Elastic;
  import org.libspark.betweenas3.easing.Exponential;
  import org.libspark.betweenas3.easing.Quad;
  import org.libspark.betweenas3.easing.Quart;
  import org.papervision3d.objects.DisplayObject3D;

  public class LetterHelper
  {
    
    public static var LINE_SPACE:Number = 16; 
    public static function place(...rest):Number {
      return place_array(rest)
    }

    public static function place_array(a:Array, scale:Number = 1):Number {
      var last_y:Number = 0, l:Letter, current_width:Number
      a.forEach(function(l:Letter, ...remainder):void {
          l.destination_scale = scale
          current_width = BookConfig.TYPEFACE.widths[l.string]*l.destination_scale
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

    public static function character_width(character:String):Number {
      return BookConfig.TYPEFACE.widths[character]
    }
     
    public static function line(content:String, index:Number, a:Array, justify:Boolean=false, phrase:Array=null, container:DisplayObject3D=null, max_line_width:Number=0, prepopulated:Boolean=false, intro_type:String='from_marker'):Number {
      
      var display:Array = StringHelper.trim(content).split("");
      var letters:Array = [];
      var erasures:Object = {};   
      var i:Number = -1, num_letters:Number = display.length, letter:Letter
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
          text_width+=character_width(k)*scale
          if (erasable) erasures[i-skipped] = 1;
        } else {
          num_spaces++
        }
        
        letters.push(k)
      }
      
      if (text_width > max_line_width) max_line_width = text_width
      
      var space_size:Number = (text_width < line_width/BookConfig.LINE_JUSTIFICATION_TOLERANCE || !justify || last_line) ? character_width(" ")*scale : (line_width - text_width)/num_spaces
      
      if (last_line) last_y+= max_line_width - (text_width)
      
      //trace("\nWriting line:" + num_letters + "|" + prepopulated )
      num_letters-=skipped;
      i = -1;
      
      var time:Number = 0;
     
      while (++i < num_letters) {
        if (!letters[i]) continue; //we don't have this letter. 
        letter = (prepopulated) ? phrase[index][i] : new Letter(letters[i] as String)
        
        letter.erasable = (erasures[i])
        
        //set where we're going. 
        letter.destination_scale=scale
        current_width = (letter.string==" ") ? space_size : character_width(letter.string)*letter.destination_scale
        
        letter.destination_x = 40
        letter.destination_y = last_y + current_width/2
        letter.destination_z = -LINE_SPACE*index
        
        letter.destination_rx = 90
        letter.destination_ry = 0
        letter.destination_rz = 90
          
        letter.destination_alpha=1
        last_y+=current_width
          
        switch(intro_type) {
          case "from_marker":
            place_at_marker(letter)
            break;
          case "none":
            match_to_destination(letter); 
            break;
        }
          

        if (!prepopulated) {
          if (!phrase[index]) phrase[index] = []; 
          phrase[index].push(letter);   
        }

        container.addChild(letter.character)
        letter.move_to(time);
      } 
      
      return max_line_width
      
    }    
    
    public static function place_at_marker(letter:Letter):void {
      
      letter.character.x = 0
      letter.character.y = 0
      letter.character.z = -200
        
      letter.character.scaleX = 0.01;
      letter.character.scaleY = 0.01;
      letter.character.scaleZ = 0.01; 
      
      letter.character.rotationX = 90; 
      letter.character.rotationY = 0;
      letter.character.rotationZ = 90;       
    }
    
    public static function match_to_destination(letter:Letter):void {
     
      letter.character.x = letter.destination_x;
      letter.character.y = letter.destination_y;
      letter.character.z = letter.destination_z;
      
      letter.character.scaleX = letter.destination_scale;
      letter.character.scaleY = letter.destination_scale;
      letter.character.scaleZ =  letter.destination_scale; 
      
      letter.character.rotationX = letter.destination_rx; 
      letter.character.rotationY = letter.destination_ry;
      letter.character.rotationZ = letter.destination_rz; 
      letter.character.alpha = letter.destination_alpha;
    }
       
    public static function exit(l:Letter, container:Sprite, on_complete:Function=null, outro:String  = 'explode'):void {
      if (!l || !container) return; 

      //the letters are rotated in space, so:
      //z = down
      //y = left/right
      //x = up down
      
      var time:Number = 0;
      var easing:IEasing = Quad.easeIn
      
      switch (outro) {
        case 'drop':
          l.destination_y     =  l.character.y
          l.destination_z     =-200; //Drop straight down.
          l.destination_x     = l.character.x
          l.destination_rx    = NumberHelper.random(-360,360)
          l.destination_ry    = NumberHelper.random(-360,360)
          l.destination_rz    =  NumberHelper.random(-360,360)
          l.destination_scale = 0
          l.destination_alpha = 1        
          break;
        case 'up':   
          l.destination_x     = l.character.x
          l.destination_y     = l.character.y
          l.destination_z     = 400
          l.destination_rx    = l.character.rotationX
          l.destination_ry    = l.character.rotationY
          l.destination_rz    = l.character.rotationZ
          l.destination_scale = 0
          l.destination_alpha = 1          
          break;
        case 'recede':
          l.destination_x     = 300
          l.destination_y     = 60
          l.destination_z     = -120;    
          l.destination_rx    = NumberHelper.random(-360,360)
          l.destination_ry    = NumberHelper.random(-360,360)
          l.destination_rz    =  NumberHelper.random(-360,360)
          l.destination_scale = 0
          l.destination_alpha = 1
          easing = Exponential.easeIn
          break;
        case 'explode':
        default:
          l.destination_x     = NumberHelper.random(-(container.stage.width*2)/2,(container.stage.width*4)/2)
          l.destination_y     = NumberHelper.random(-(container.stage.width*2)/2,(container.stage.width*4)/2)
          l.destination_z     = NumberHelper.random(-(container.stage.height*2)/2,(container.stage.height*4)/2)
          
          l.destination_rx    = NumberHelper.random(-360,360)
          l.destination_ry    = NumberHelper.random(-360,360)
          l.destination_rz    = NumberHelper.random(-360,360)
          
          l.destination_scale = NumberHelper.random(-1000,1000)/100
          l.destination_alpha = 1
          break;
        
      }
     
      if (on_complete !=null) l.addEventListener(Event.COMPLETE, on_complete);
      l.move_to(time, easing)
    }

  }
}