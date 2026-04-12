# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/20
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# uses :convert to break pvid into array with 2 elements between 0-256
    :local vlanbytes [:convert from=num to=byte-array $vlanid]  
    :local lowbits ($vlanbytes->0)
    :local highbits ($vlanbytes->1)

    # UGLY workaround for MIPSBE/other, detected when we don't get two parts from the vlan-id
    :if ([:len $vlanbytes]>2) do={
        :if ($vlanid > 255) do={
            # even worse workaround, normalize to 8 bytes - ros wrongly trims leading 0
            :if ([:len $vlanbytes]=7) do={ 
                # make it len=8 by pre-pending a 0 - so the swap below is correct
                :set vlanbytes (0,$vlanbytes) 
            }
            # now swap the high and low bytes
            :set lowbits ($vlanbytes->1)
            :set highbits ($vlanbytes->0)  
        } 
        # lowbits is right if under 256
    }
