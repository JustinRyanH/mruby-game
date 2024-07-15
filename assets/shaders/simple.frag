#version 330

// Input fragment attributes (from fragment shader)
in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform sampler2D texture1;

// Output fragment color
out vec4 finalColor;

void main()
{
    // Texel color fetching from texture sampler
    // NOTE: The texel is actually the a GRAYSCALE index color
    vec4 texel_color_a = texture(texture0, fragTexCoord)*fragColor;
    vec4 texel_color_b = texture(texture1, fragTexCoord);

    vec4 shader_out_test = vec4(texel_color_a.rgb, 0) + vec4(0, 0, 0, texel_color_a.a * texel_color_b.a);

    finalColor = shader_out_test;
}
