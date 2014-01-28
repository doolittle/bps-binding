package com.betweenpageandscreen.binding.views.modules
{
  import com.betweenpageandscreen.binding.config.BookConfig;
  import com.betweenpageandscreen.binding.helpers.LetterHelper;
  import com.bradwearsglasses.utils.helpers.NumberHelper;
  
  import flash.events.Event;
  import flash.events.EventDispatcher;
  
  import org.libspark.betweenas3.BetweenAS3;
  import org.libspark.betweenas3.core.easing.IEasing;
  import org.libspark.betweenas3.core.tweens.ObjectTween;
  import org.libspark.betweenas3.easing.Quad;
  import org.papervision3d.materials.special.Letter3DMaterial;
  import org.papervision3d.typography.Letter3D;

  public class Letter extends EventDispatcher {
    public var character:Letter3D;
    public var destination_z:Number;
    public var destination_y:Number;
    public var destination_x:Number;
    public var destination_rx:Number;
    public var destination_ry:Number;
    public var destination_rz:Number;
    public var destination_alpha:Number;
    public var destination_scale:Number;
    public var erasable:Boolean = false; 
    private var material:Letter3DMaterial;
    private var color:uint;
    public var string:String;
    public var width:Number;
    private var tweener:ObjectTween;
      
    public function Letter(l:String=null)	{
      string = l;
      color = BookConfig.LETTER_COLOR;
      material = new Letter3DMaterial(color, 1);
      material.doubleSided    = true;
      material.baked          = true;
      material.smooth         = false;
      material.interactive    = false;
      //material.scaleStroke  = true;
      character               = new Letter3D(string, material,BookConfig.TYPEFACE);
      character.scale         = .05;
      character.rotationX     = 90;
      character.rotationZ     = 90;
      width = LetterHelper.character_width(string);
    }
    
    public function freeze():void {
      if (tweener) tweener.stop();
    }

    public function move_to(time:Number = 0, easing:IEasing = null):void {
      if (!easing) easing = Quad.easeIn;
      var duration:Number = (time ==0) ? NumberHelper.random(50,100)/125 : time;
      var params:Object = {
        x: destination_x,
        y: destination_y,
        z: destination_z,
        rotationX: destination_rx,
        rotationY: destination_ry,
        rotationZ: destination_rz,
        scaleX: destination_scale,
        scaleY: destination_scale,
        scaleZ: destination_scale,
        alpha: destination_alpha
      };
      tweener = BetweenAS3.tween(character,params,null,duration,easing) as ObjectTween;
      tweener.onComplete = do_complete;
      tweener.play();
    }
    
    private function do_complete():void {
      dispatchEvent(new Event(Event.COMPLETE));
    }
  }
}
