/// <summary>
/// The Vertex declaration to be used for each individual instance of your models. The transform should contain positional, rotational, and scale data.
/// Also threw in color for fun
/// </summary>
public struct ModelInstanceVertex : IVertexType
{
    public static readonly int Stride = 64 + sizeof(byte) * 4;

    public Matrix Transform;
    public Color Color;

    public ModelInstanceVertex(Matrix transform, Color color)
    {

        Transform = transform;
        Color = color;
 

    }
    public static readonly VertexDeclaration declaration = new VertexDeclaration(

     new VertexElement(0, VertexElementFormat.Vector4, VertexElementUsage.BlendWeight, 0),
     new VertexElement(16, VertexElementFormat.Vector4, VertexElementUsage.BlendWeight, 1),
     new VertexElement(32, VertexElementFormat.Vector4, VertexElementUsage.BlendWeight, 2),
     new VertexElement(48, VertexElementFormat.Vector4, VertexElementUsage.BlendWeight, 3),
     new VertexElement(64, VertexElementFormat.Color, VertexElementUsage.Color, 0)
     );

    VertexDeclaration IVertexType.VertexDeclaration
    {
        get { return declaration; }
    }

}