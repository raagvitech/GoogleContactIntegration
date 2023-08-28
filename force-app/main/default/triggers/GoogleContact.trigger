trigger GoogleContact on Contact (after insert, after update) {        
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert && !GoogleApiQueueable.isDisableTrigger)
        { 
            System.enqueueJob(new GoogleApiQueueable(Trigger.new,false));
        }
    }
        
   if(Trigger.isAfter){
        if(Trigger.isUpdate && !GoogleApiQueueable.isDisableTrigger)
        {
           System.enqueueJob(new GoogleApiQueueable(Trigger.new,true)); 
        }
    } 
}