# FS22_realismAddon_fillables
 This Script is made to enhance realism on fillable vehicles. It consists of mainly two things.
 1. With default FS22, all fillTypes have real mass (and not half of real as in previous FS versions)
		If you play with the trailer fill limit enabled it allows you to only fill trailers until the max allowed weight of that trailer is reached through the amount of the particular fillType.
		If you play without the trailer fill limit enabled you can fill trailers up to 100% no matter what, BUT it will never weight more than max allowed weight. This means that the additional mass that would make the trailer heavier is discarded.
		This way it enables for unrealistically high capacities and casual players to not worry about having enough horsepower to pull a trailer. But for realism players this isn't enough.
 		So this mod changes that. With trailer fill limit disabled you can load past the max allowed weight and the mass will be added. Also if you have the trailer selected it will show the % of overload below the fillLevel bar.
 		In addition to that, if you have the trailer overloaded it will amount more damage when driving. The faster you drive the more damage amounts (speed^2) so if you need to overload your trailer, drive slowly unless you want to repair it often.

 2. The second feature of this script is to not have a rigid capacity limit. You can fill trailers past 100%, BUT the further above 100% you fill the more of the fill gets "spilled" e.g. lost. 
 		This is simply because IRL you don't have any rigid limits either. If you have 150l left in your combine you don't need another trailer for that, or if you're full just a few meters away from the field ending you don't need to unload first.
		The loss is 0% at 100% capacity and 100% at 130% capacity but the actual loss amount is also a bit random up to 20% more than the mathematical loss, so as soon as 100% capacity are reached you can lose up to 20% of each further filling
		You can toggle this feature on/off on each vehicle by the additonal input-binding (needs to be mapped first, is not mapped by default)
		It is automatically on by default but for playing with Courseplay or AutoDrive it needs to be toggled off otherwise the helper will fill trailers up to 130% accumulating a lot of loss.

# Credits
- Modelleicher

# Changelog:


###### V 0.3.0.5
- fixed wheels-mass being added twice 

###### V 0.3.0.4
- fixed wrong capacity with excluded fillTypes in Multiplayer (water etc.)
- deactivated automatic turn-off in forageWagons at 100% (careful, you have to turn off the wagon yourself otherwise it will load to 129% with a lot of loss)
- fixed loss-calculation to have less loss at few % over 100, maximum loss at 130% is not 100% anymore either - random component on each level 

###### V 0.3.0.3
- added spec_baler to exclude List to stop Biobaler from overloading
###### V 0.3.0.2
- Fixed last Multiplayer Issues, should now no longer be any issues in Multiplayer 
- added Input to disable filling above 100% on each vehicle individually (to deactivate it when playing with AutoDrive/Courseplay so they don't keep filling to 130%)
###### V 0.3.0.1
- Fixed MixerWagons not working correctly in Multiplayer
###### V 0.3.0.0
- Initial Github Release for FS22, 12th of Mai 2022 




