#include "BlockHooks.as";
// Add this file to a block's cfg if the block will use custom hooks
void onInit(CBlob@ this)
{
    BlockHooks blockHooks;
    this.set("BlockHooks", @blockHooks); 
}
