module MiniFBDisplay

using MiniFB
using ImageTransformations: imresize
using ColorTypes: ARGB32 
using FileIO: load
import ImageIO

struct MiniFBDisplayType <: AbstractDisplay end

function Base.display(d::MiniFBDisplayType, m::MIME"image/png", x)
    io = IOBuffer()
    show(io, m, x)
    img = load(io)
    img_height, img_width = size(img)
    ratio = min(1, 600 / img_height, 600 / img_width)
    img_buffer = imresize(img; ratio) .|> ARGB32
    win_height, win_width = size(img_buffer)
    window = mfb_open_ex("MiniFB Display", win_width, win_height, MiniFB.WF_RESIZABLE)
    GC.@preserve window begin
        @async while true # mfb_wait_sync(window)
            state = mfb_update(window, img_buffer |> permutedims)
            if state != MiniFB.STATE_OK
                mfb_close(window)
                break
            end
            yield()
            sleep(0.08)
        end
    end
end

function Base.display(d::MiniFBDisplayType, x)
    if showable("image/png", x)
        display(d, "image/png", x)
    else
        # fall through to the Displays lower in the display stack
        throw(MethodError(display, "nope"))
    end
end

function __init__()
    # mfb_set_target_fps(60)
    Base.Multimedia.pushdisplay(MiniFBDisplayType())
end

end # module
