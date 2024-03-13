/// <summary>
/// You should have an instance of ModelBuffer for every model in your game. This allows you to only need to issue a single draw call per model TYPE (not instance),
/// which has massive performance gains
/// </summary>
public class ModelBuffer
{
    private static readonly ushort _maxModels = 12000;
    private static readonly ushort _maxVerticies = 12000;

    public readonly string Key;
    private readonly GraphicsDevice _graphics;
    private readonly Model _model;

    private ModelInstanceVertex[] _positions;
    private DynamicVertexBuffer _instanceVertexBuffer;
    public ushort TotalInstances { get; private set; }

    private float _intensity = 1f;
    private bool _increasing = false;
    public ModelBuffer(GraphicsDevice graphics, string key, Model model)
    {
        _graphics = graphics;
        Key = key;
        _model = model;


        _positions = new ModelInstanceVertex[_maxModels];
        _instanceVertexBuffer = new DynamicVertexBuffer(_graphics, typeof(ModelInstanceVertex), _maxVerticies, BufferUsage.WriteOnly);


    }


    public void SetInstance(Matrix matrix, Color color)
    {

        ModelInstanceVertex vertex = new ModelInstanceVertex(matrix, color);

        _positions[TotalInstances] = vertex;
        TotalInstances++;



    }

    public void SetBuffer()
    {

        _instanceVertexBuffer.SetData<ModelInstanceVertex>(0, _positions, 0, TotalInstances, ModelInstanceVertex.Stride);

    }



    public void Draw(GameTime gameTime, float alphaTestDirection, LightCollection lightCollection)
    {
        //Giving the lights a pulse effect
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds / 3f;
        float upperBound = 1f;
        float lowerBound = .2f;
        if (_increasing)
            _intensity += dt;
        else
            _intensity -= dt;
        if (_intensity >= upperBound)
        {
            _intensity = upperBound;
            _increasing = false;

        }
        else if (_intensity <= lowerBound)
        {
            _intensity = lowerBound;
            _increasing = true;
        }

        for (int i = 0; i < lightCollection.Intensities.Length; i++)
        {
            lightCollection.Intensities[i] = _intensity;
        }

        Color sunLightColor = Color.White;
        Vector3 sunLightDirection = new Vector3(0, -1f, 0);
        float sunLightIntensity = Settings.Data.WorldBrightness;
        foreach (ModelMesh mesh in _model.Meshes)
        {
            foreach (ModelMeshPart meshPart in mesh.MeshParts)
            {
                // Tell the GPU to read from both the model vertex buffer plus our instanceVertexBuffer.
                _graphics.SetVertexBuffers(
                new VertexBufferBinding(meshPart.VertexBuffer, meshPart.VertexOffset, 0),
                new VertexBufferBinding(_instanceVertexBuffer, 0, 1)
            );
                _graphics.Indices = meshPart.IndexBuffer;
                if (Settings.Data.EnabledLighing && lightCollection.Positions.Length > 0)
                {

                    meshPart.Effect.CurrentTechnique = meshPart.Effect.Techniques["LightingModelInstancing"];


                    meshPart.Effect.Parameters["SunLightDirection"].SetValue(sunLightDirection);
                    meshPart.Effect.Parameters["SunLightColor"].SetValue(sunLightColor.ToVector4());
                    meshPart.Effect.Parameters["SunLightIntensity"].SetValue(sunLightIntensity);
                    meshPart.Effect.Parameters["CameraPosition"].SetValue(Game1.Camera3D.Position);

                    meshPart.Effect.Parameters["FogEnabled"].SetValue(Settings.Data.FogAmount > 0 ? 1f : 0f);

                    meshPart.Effect.Parameters["FogColor"].SetValue(Color.White.ToVector3());

                    meshPart.Effect.Parameters["FogAmount"].SetValue(Settings.Data.FogAmount * 10000);
                    meshPart.Effect.Parameters["MaxLightsRendered"].SetValue(lightCollection.Positions.Length);

                    meshPart.Effect.Parameters["PointLightPosition"].SetValue(lightCollection.Positions);
                    meshPart.Effect.Parameters["PointLightColor"].SetValue(lightCollection.Colors);
                    meshPart.Effect.Parameters["PointLightIntensity"].SetValue(lightCollection.Intensities);
                    meshPart.Effect.Parameters["PointLightRadius"].SetValue(lightCollection.Radii);


                }
                else
                {
                    meshPart.Effect.CurrentTechnique = meshPart.Effect.Techniques["ModelInstancing"];

                }

                meshPart.Effect.Parameters["Projection"].SetValue(Game1.Camera3D.ProjectionMatrix);
                meshPart.Effect.Parameters["View"].SetValue(Game1.Camera3D.ViewMatrix);



                // Draw all the instance copies in a single call
                foreach (EffectPass pass in meshPart.Effect.CurrentTechnique.Passes)
                {
                    pass.Apply();
                    StageManager.NumDrawCalls++;

                    _graphics.DrawInstancedPrimitives(PrimitiveType.TriangleList, 0, 0,
                                                           meshPart.NumVertices, meshPart.StartIndex,
                                                           meshPart.PrimitiveCount, TotalInstances);
                }
            }
        }
        TotalInstances = 0;
    }



}