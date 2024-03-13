This shows the bread and butter for model instancing in Monogame.

It's an incomplete example as much of the other code is fairly dispersed across my main game project, but this shows the important logic and should help get you started.

![showcase](https://github.com/captainkidd5/InstancedShader/assets/34559523/8e1b6a7d-e31f-4f10-a42f-d9bc503c413f)

It includes support for up to 20 lights (specular/ambient) and fog.

Fog is currently pretty scuffed so I strongly welcome pull requests to get it ironed out!


Note that you will need to create a content pipeline extensions and use the code from InstancedModelProcessor.cs
Then, when adding your assets in the content pipeline choose .FBX importer and the InstancedModelProcessor for the processor.