/* Number of linked prims that form the width. */
integer links_across = 8;

/* Number of linked prims that form the height. */
integer links_down = 16;

/* Number of horizontal faces per row of each prim. */
integer faces_across = 4;

/* Number of verical faces per column of each prim. */
integer faces_down = 2;

/* Whether to use ALL_SIDES for the pixel face. */
integer all_sides = FALSE;

integer channel;
integer listener;

set_link_labels(integer toggle)
{
    if (toggle)
    {
        integer prims = llGetNumberOfPrims();
        integer i;
        
        for (i = 1; i <= prims; ++i)
        {
            llSetLinkPrimitiveParamsFast(i, [PRIM_TEXT, (string) i, <1, 1, 1>, 1]);
        }
    }
    else
    {
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_TEXT, "", ZERO_VECTOR, 0]);
    }
}

/* Align the linked prims in a square grid. */
align_prims()
{
    integer prims = llGetNumberOfPrims();
    vector scale = llGetScale();
        
    integer i;
    float x = scale.y;
    float y = 0;
    
    for (i = 2; i <= prims; ++i)
    {        
        llSetLinkPrimitiveParamsFast(i, [PRIM_POS_LOCAL, <0, x, y>]);
        
        x += scale.y;
        
        if (x >= scale.y * links_across)
        {
            y -= scale.z;
            x = 0;
        }
    }
}

integer pixel_link(integer x, integer y)
{
    return (integer) ((x / faces_across) + (y / faces_down * links_across)) + 1;
}

integer pixel_face(integer x, integer y)
{
    if (all_sides)
    {
        return ALL_SIDES;
    }
    else
    {
        return (x % faces_across) + (y % faces_down * faces_across);
    }
}

plot(integer x, integer y, vector color)
{
    llSetLinkColor(pixel_link(x, y), color, pixel_face(x, y));
}

fill(vector color)
{
    llSetLinkColor(LINK_SET, color, ALL_SIDES);
}

integer is_whitespace(string c)
{
    return c == " " || c == "\n";
}

key http_request_id;

draw_ppm(string ppm)
{
    integer i;
    integer len = llStringLength(ppm);
    
    string magic;
    
    integer width = -1;
    integer height = -1;
    
    string buffer;
    
    integer max = -1;
    
    integer r = -1;
    integer g = -1;
    integer b = -1;
    
    integer comment = FALSE;
    
    integer x;
    integer y;
    
    for (i = 0; i <= len; ++i)
    {
        string c;
        
        if (i < len)
        {
            c = llGetSubString(ppm, i, i);
        }
        else
        {
            c = " ";
        }
        
        if (comment)
        {
            if (c == "\n")
            {
                comment = FALSE;
            }
        }
        else if (c == "#")
        {
            comment = TRUE;
        }
        else if (is_whitespace(c))
        {
            if (buffer != "")
            {
                if (magic == "")
                {
                    magic = buffer;
                    
                    if (magic != "P3")
                    {
                        llOwnerSay("Invalid format");
                        return;
                    }
                }
                else if (width == -1)
                {
                    width = (integer) buffer;
                    
                    if (width != links_across * faces_across)
                    {
                        llOwnerSay("Incorrect image size");
                        return;
                    }
                }
                else if (height == -1)
                {
                    height = (integer) buffer;
                    
                    if (height != links_down * faces_down)
                    {
                        llOwnerSay("Incorrect image size");
                        return;
                    }
                }
                else if (max == -1)
                {
                    max = (integer) buffer;
                }
                else if (r == -1)
                {
                    r = (integer) buffer;
                }
                else if (g == -1)
                {
                    g = (integer) buffer;
                }
                else if (b == -1)
                {
                    b = (integer) buffer;
                    
                    float r1 = (float) r / max;
                    float g1 = (float) g / max;
                    float b1 = (float) b / max;
                                    
                    vector color = <r1, g1, b1>;
        
                    plot(x, y, color);
                    
                    x++;
                            
                    if (x == width)
                    {
                        x = 0;
                        y++;
                    }
                    
                    r = -1;
                    g = -1;
                    b = -1;
                }
                
                buffer = "";
            }
        }
        else
        {
            buffer += c;
        }
    }
}

default
{
    state_entry()
    {
        /* Get a unique channel number based on the object's key. */
        channel = 0x80000000 | (integer)("0x"+(string)llGetKey());
        
        set_link_labels(TRUE);
        
        state set_links_across;
    }    
}

state set_links_across
{
    state_entry()
    {
        llListen(channel, "", llGetOwner(), "");
        llTextBox(llGetOwner(), "Enter links across:", channel);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        links_across = (integer) message;
        
        state set_links_down;
    }
}

state set_links_down
{
    state_entry()
    {
        llListen(channel, "", llGetOwner(), "");
        llTextBox(llGetOwner(), "Enter links down:", channel);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        links_down = (integer) message;
        
        state set_faces_across;
    }
}

state set_faces_across
{
    state_entry()
    {
        llListen(channel, "", llGetOwner(), "");
        llTextBox(llGetOwner(), "Enter faces across:", channel);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        faces_across = (integer) message;
        
        state set_faces_down;
    }
}

state set_faces_down
{
    state_entry()
    {
        llListen(channel, "", llGetOwner(), "");
        llTextBox(llGetOwner(), "Enter faces down:", channel);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        faces_down = (integer) message;
        
        if (faces_across == 1 && faces_down == 1)
        {
            all_sides = TRUE;
        }
        
        state main;
    }
}

state main
{
    state_entry()
    {
        align_prims();
        
        set_link_labels(FALSE);
        
        fill(<0, 0, 0>);        
    }
    
    touch_start(integer detected)
    {
        key toucher = llDetectedKey(0);
        
        if (toucher != llGetOwner())
        {
            return;
        }
        
        llListenRemove(listener);
        listener = llListen(channel, "", toucher, "");
        llTextBox(toucher, "Enter the URL of an ASCII PPM:", channel);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        llHTTPRequest(message, [HTTP_BODY_MAXLENGTH, 16384], "");
    }
    
    http_response(key request_id, integer status, list metadata, string body)
    {
        if (status == 200)
        {
            draw_ppm(body);
        }
    }
}
