package com.betweenpageandscreen.binding.views.pages
{
import com.betweenpageandscreen.binding.events.BookEvent;
import com.betweenpageandscreen.binding.fonts.BookHelveticaBold;
import com.betweenpageandscreen.binding.helpers.LetterHelper;
import com.betweenpageandscreen.binding.views.modules.BookModule;
import com.betweenpageandscreen.binding.views.modules.Letter;
import com.bradwearsglasses.utils.debug.DebugTimer;
import com.bradwearsglasses.utils.helpers.GeneralHelper;
import com.bradwearsglasses.utils.helpers.NumberHelper;

import flash.display.Sprite;
import flash.events.Event;

import org.libspark.flartoolkit.support.pv3d.FLARMarkerNode;
import org.papervision3d.objects.DisplayObject3D;

public class Epistle extends BookModule
{
  private var container:Sprite;
  private var marker:FLARMarkerNode;

  private var content:String;
  private var lines:Array;
  private var phrase:Array = [];

  private var max_line_width:Number = 0;
  private var text:DisplayObject3D;
  private var justify:Boolean = false;

  private var to_destroy:Number = 0;
  private var destroyed:Number = 0;

  private var helv:BookHelveticaBold = new BookHelveticaBold;

  private var text_id:Number;

  public function Epistle(s:String, _justify:Boolean=true){
    text_id = GeneralHelper.generate_id();
    content = s;
    justify = _justify;
    text = new DisplayObject3D;
    lines = content.split("\n");
  }

  override public function init(c:Sprite, m:*):void {
    removeEventListener(BookEvent.MODULE_DESTROY,destroy);
    container = c;
    marker = m as FLARMarkerNode;
    trace(text_id + ":\tIniting epistle:" + phrase.length + " letters and " + lines.length + " lines")
    iterate_phrase(phrase,
        function(l:Letter, ...rest):void {
          destroy_letter(null, l, true);
        });
  }

  override public function intro():void {
    trace("introing epistle:" + text_id);
    text.z = -120;
    text.x = 45;
    text.y = 0;
    text.rotationX = 180;
    text.rotationY = 0;
    text.rotationZ = 270;
    text.scale = .66;
    var prepopulated:Boolean = (phrase.length > 0);
    var timer:DebugTimer = new DebugTimer("Creating lines (" + prepopulated + ")");

    lines.forEach(function(...rest):void {
      max_line_width = LetterHelper.line(rest[0], rest[1], rest[2], justify, phrase, text, max_line_width,prepopulated);
    })
    timer.mark("Lines created");
    marker.addChild(text)
  }

  override public function tick():void {}

  override public function remove():void {
    addEventListener(BookEvent.MODULE_DESTROY,destroy);
    explode();
  }

  private function explode():void {
    trace("Exploding flat text");
    to_destroy = 0;
    destroyed = 0;
    var outro:String = 'explode'; //ArrayHelper.random(['explode', 'drop', 'up']) as String
    iterate_phrase(phrase, function(l:Letter, ...rest):void {
      to_destroy++;
      if (NumberHelper.sample(5)) return destroy_letter(null, l, true) //drop 20% to make remainder faster.
      LetterHelper.exit(l, container, destroy_letter,outro);
    })
  }

  private function destroy_letter(event:Event=null, _l:Letter=null, auto:Boolean=false):void {
    var l:Letter = (_l) ? _l :  event.target as Letter;
    l.removeEventListener(Event.COMPLETE, destroy_letter);
    text.removeChild(l.character);
    if (++destroyed >= to_destroy && !auto) request_destroy();
  }

  private function destroy(event:*=null):void {
    trace("Destroying flat text")
    marker.removeChild(text)
  }

}
}
