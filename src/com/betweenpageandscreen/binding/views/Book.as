package com.betweenpageandscreen.binding.views {

import com.betweenpageandscreen.binding.config.BookConfig;
import com.betweenpageandscreen.binding.events.BookEvent;
import com.betweenpageandscreen.binding.models.CameraParams;
import com.bradwearsglasses.utils.helpers.GraphicsHelper;
import com.bradwearsglasses.utils.helpers.LayoutHelper;
import com.bradwearsglasses.utils.helpers.SpriteHelper;

import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import org.libspark.betweenas3.BetweenAS3;
import org.libspark.betweenas3.core.tweens.ObjectTween;
import org.libspark.betweenas3.easing.Quad;
import org.libspark.betweenas3.tweens.ITween;

public class Book extends Sprite {

  public var videoDisplay:VideoDisplay = new VideoDisplay;
  public var display_port:Sprite;

  private var scale:Matrix  = new Matrix;
  private var border:Sprite;
  private var pulse:Sprite;
  private var exit:ObjectTween;
  private var waiter:ITween;

  public function Book(){

    scale.scale(BookConfig.DOWNSAMPLE, BookConfig.DOWNSAMPLE);

    var bounds:Rectangle  = GraphicsHelper.rect(BookConfig.VIEW_WIDTH, BookConfig.VIEW_HEIGHT);
    display_port = GraphicsHelper.strut(new Sprite,bounds);

    bounds.inflate(8,8);
    border = GraphicsHelper.recession(new Sprite, bounds,0x888888);

    pulse = GraphicsHelper.box(new Sprite, GraphicsHelper.rect(10, 10),0x000000,1);

    border.scaleX = border.scaleY = 0;

    SpriteHelper.add_these(display_port, border, videoDisplay);
    SpriteHelper.add_these(this, display_port);
  }

  public function wait():void {
    LayoutHelper.in_center(this, this, pulse,new Point(0,0),true);
    var loop_in:ObjectTween = BetweenAS3.tween(pulse,{x:pulse.x+15},{x:pulse.x-15},.5, Quad.easeInOut) as ObjectTween;
    exit = BetweenAS3.tween(pulse,{x:pulse.x, alpha:0, scaleX:0, scaleY:0},null,.2, Quad.easeInOut) as ObjectTween;
    waiter = BetweenAS3.repeat(BetweenAS3.serial(loop_in, BetweenAS3.reverse(loop_in)),9999);
    waiter.play();
  }

  public function stop_waiting():void {
    if (!waiter) return;
    waiter.stop();
    exit.play();
  }

  public function intro():void {
    SpriteHelper.destroy(pulse);
    LayoutHelper.in_center(display_port, display_port, border, null,true);
    var params:Object = {y: 0, x:0,  scaleX:1, scaleY:1};
    var tween:ObjectTween = BetweenAS3.tween(border,params,null,.75,Quad.easeIn) as ObjectTween;
    tween.onComplete = complete_intro;
    tween.play();
  }

  protected function complete_intro(event:Event=null):void {
    BetweenAS3.tween(videoDisplay.screen,{alpha:0},null,1.5,Quad.easeIn).play();

    // TODO: Fix double broadcast
    dispatchEvent(new BookEvent(BookEvent.BOOK_COMPLETE));
    dispatchEvent(new BookEvent(BookEvent.VIEW_PREPPED));
  }

  public function setup(params:CameraParams):void {
    videoDisplay.setup(params);
  }

  public function start():void {
    videoDisplay.start();
  }

}
}
