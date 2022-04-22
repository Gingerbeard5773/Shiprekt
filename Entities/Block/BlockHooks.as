// Gingerbeard @ 1/1/2022
funcdef void Hook(CBlob@); //define hooks of this type

class BlockHooks           
{
	//Hook@[] Hooks;

	private dictionary HooksDict;

	BlockHooks()
	{
		Hook@[] key1;
		Hook@[] key2;
		//initialize the dictionary when a BlockHooks object is constructed
		HooksDict.set("onBlockPlaced", @key1); //called when the block is placed down from a human
		HooksDict.set("onColored", @key2); //called when the block's color is changed
	}

	void addHook(string key, Hook@ hook)
	{
		Hook@[]@ Hooks;
        HooksDict.get(key, @Hooks);
		
		const int hooksLength = Hooks.length;
		for (int i = 0; i < hooksLength; i++)
		{
			if (hook is Hooks[i]) return;
		}
		
		Hooks.push_back(hook);
	}

	void update(string key, CBlob@ this)
	{
		Hook@[]@ Hooks;
        HooksDict.get(key, @Hooks);
		
		const int hooksLength = Hooks.length;
		for (int i = 0; i < hooksLength; i++)
		{
			Hooks[i](@this); //find hooks and activate them
		}
	}
}
