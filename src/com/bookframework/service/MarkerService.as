package com.bookframework.service
{
  import com.bookframework.events.BookEvent;
  import com.bookframework.models.Markers;
  import com.bradwearsglasses.utils.helpers.ArrayHelper;
  import com.bradwearsglasses.utils.queue.Queue;
  import com.bradwearsglasses.utils.queue.QueueEvent;
  import com.bradwearsglasses.utils.service.GenericService;
  import com.bradwearsglasses.utils.service.GenericServiceEvent;
  
  import flash.events.Event;

  public class MarkerService extends BookService
  {
    [Inject]
    public var markers:Markers;
    
    private var markers_to_load:Array
   
    public function markers_from_cache(markers:Array):void {
      var reduce:Queue = new Queue(markers, this, add_marker, null, false,1)
      reduce.addEventListener(QueueEvent.QUEUE_COMPLETE, complete_markers)
      reduce.start()
    }
    
    private function complete_markers(event:Event):void {
      dispatch(new BookEvent(BookEvent.MARKERS_COMPLETE)) 
    }  
    
    private function add_marker(marker:String):void {
      markers.add(marker); 
    }
    
    public function load_all_markers(_markers_to_load:Array):void {
      trace("@@TODO: Loading all markers -- doesn't exist yet")
      markers_to_load = _markers_to_load; 
      load_next_marker(markers_to_load.shift() as String)
    }
    
    private function load_next_marker(marker_path:String):void {

      trace("Loading code:" + marker_path)
      var service :GenericService= new GenericService()
      service.addEventListener(GenericServiceEvent.REQUEST_COMPLETE, load_marker_complete)
      service.addEventListener(GenericServiceEvent.REQUEST_FAIL, load_marker_fail); 
      service.request(marker_path) 
    }
        
    private function load_marker_complete(event:GenericServiceEvent):void {
      var loaded_event:BookEvent = new BookEvent(BookEvent.MARKER_LOADED,"loaded")
      loaded_event.data = event.data
      dispatch(loaded_event)
      
      if (markers_to_load.length > 0) {
        trace("\nWe've got to load another code")
        load_next_marker(markers_to_load.shift() as String)
      } else {
        trace("\nWe're all done loading codes")
        dispatch(new BookEvent(BookEvent.MARKERS_COMPLETE)) 
      }
    }
    
    private function load_marker_fail(event:GenericServiceEvent):void {
      trace("Failed load markers:")
      dispatch(event)
    }        
    
  }
}