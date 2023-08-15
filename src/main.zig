const std = @import("std");
const log = std.log;
const SDL = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub fn main() !void {
    const alc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alc);
    defer std.process.argsFree(alc, args);

    if (args.len < 4) {
        std.debug.print("Usage: {s} input_file width height\n", .{args[0]});
        std.os.exit(1);
    }
    const width = try std.fmt.parseInt(u32, args[2], 10);
    const height = try std.fmt.parseInt(u32, args[3], 10);
    var infile = try std.fs.cwd().openFile(args[1], .{});
    defer infile.close();
    var input_data = try alc.alloc(u8, width * height * 3 / 2);
    defer alc.free(input_data);

    if (SDL.SDL_Init(SDL.SDL_INIT_VIDEO) != 0) {
        log.err("SDL could not initialize! SDL_Error: {s}", .{SDL.SDL_GetError()});
        return error.SDL;
    }
    defer SDL.SDL_Quit();

    var window = SDL.SDL_CreateWindow("YUV Player", SDL.SDL_WINDOWPOS_UNDEFINED, SDL.SDL_WINDOWPOS_UNDEFINED, @intCast(width), @intCast(height), SDL.SDL_WINDOW_SHOWN);
    std.debug.assert(window != null);
    defer SDL.SDL_DestroyWindow(window);

    var renderer = SDL.SDL_CreateRenderer(window, -1, SDL.SDL_RENDERER_ACCELERATED);
    std.debug.assert(renderer != null);
    defer SDL.SDL_DestroyRenderer(renderer);

    var texture = SDL.SDL_CreateTexture(renderer, SDL.SDL_PIXELFORMAT_IYUV, SDL.SDL_TEXTUREACCESS_STREAMING, @intCast(width), @intCast(height));
    std.debug.assert(texture != null);
    defer SDL.SDL_DestroyTexture(texture);

    var event: SDL.SDL_Event = undefined;
    var running = true;
    while (running) {
        if (try infile.readAll(input_data) != input_data.len) {
            break;
        }
        std.debug.assert(SDL.SDL_UpdateTexture(texture, null, input_data.ptr, @intCast(width)) == 0);

        _ = SDL.SDL_RenderClear(renderer);
        _ = SDL.SDL_RenderCopy(renderer, texture, null, null);
        SDL.SDL_RenderPresent(renderer);

        while (SDL.SDL_PollEvent(&event) != 0) {
            if (event.type == SDL.SDL_QUIT) {
                running = false;
                break;
            }
        }
    }
}
