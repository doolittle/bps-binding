package com.betweenpageandscreen.binding.helpers
{
  import com.betweenpageandscreen.binding.config.BookConfig;
  import com.betweenpageandscreen.binding.models.vo.AnalyticsRequest;
  import com.betweenpageandscreen.binding.service.BookService;
  import com.bradwearsglasses.utils.delay.Delay;

  public class AnalyticsHelper
  {

    public static const PREFIX:String = "book/"
    public static const EXCEPTION:String = "exception/"

    private static var queue:Array = []
        
    public static function event(path:String):void {
      enqueue(new AnalyticsRequest(PREFIX + path,true,AnalyticsRequest.EVENT));
    }
    
    public static function pageview(path:String):void {
      enqueue(new AnalyticsRequest(path,false));
    }	
           
    public static function exception(path:String):void {
      enqueue(new AnalyticsRequest(EXCEPTION + path,true,AnalyticsRequest.EXCEPTION));
    }	
            
    private static function enqueue(request:AnalyticsRequest):void {		  
      //trace("### QUEUEING:" + t.path)
      queue.push(request)
      if (queue.length==1) phase()
    }
    
    private static function phase():void {
      Delay.delay(1500, fire) 
    }		
    
    private static function fire():void {
      do_track(queue.shift())
      if (queue.length > 0) phase()
    }
   
    private static function do_track(request:AnalyticsRequest):void {
      if (!BookConfig.TRACK_ANALYTICS) return; 
      if (!request) return;
      if (request.event) {
        var category:String = ""
        switch (request.category) {
          default:
            category = (request.category==AnalyticsRequest.EXCEPTION) ? "exception" : "book" 
            BookService.javascript("trackEvent",[category, request.path]);
        }
      } else {
        BookService.javascript("trackPageview",[request.path]);
      } 		  
    }
  }
}
