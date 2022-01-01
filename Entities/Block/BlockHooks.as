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
		HooksDict.set("onBlockPlaced", @key1);
		HooksDict.set("onCockZucc", @key2);
	}

	void addHook(string key, Hook@ hook)
	{
		Hook@[]@ Hooks;
        HooksDict.get(key, @Hooks);

		for (int i = 0; i < Hooks.length; i++)
		{
			if (hook is Hooks[i]) return;
		}

		Hooks.push_back(hook);
	}

	void update(string key, CBlob@ this)
	{
		Hook@[]@ Hooks;
        HooksDict.get(key, @Hooks);

		for (int i = 0; i < Hooks.length; i++)
		{
			Hooks[i](@this); //find hooks and activate them
		}
	}
}
