/*
 * This file is part of mpv.
 *
 * mpv is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * mpv is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with mpv.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "clipboard.h"
#import <Cocoa/Cocoa.h>

struct clipboard_mac_priv {
    NSPasteboard *pasteboard;
    NSInteger change_count;
};

static int init(struct clipboard_ctx *cl, struct clipboard_init_params *params)
{
    (void)params;
    struct clipboard_mac_priv *p = cl->priv = talloc_zero(cl, struct clipboard_mac_priv);
    p->pasteboard = [NSPasteboard generalPasteboard];
    p->change_count = [p->pasteboard changeCount];
    return CLIPBOARD_SUCCESS;
}

static bool data_changed(struct clipboard_ctx *cl)
{
    struct clipboard_mac_priv *p = cl->priv;
    NSInteger current = [p->pasteboard changeCount];
    bool changed = current != p->change_count;
    p->change_count = current;
    return changed;
}

static int get_data(struct clipboard_ctx *cl, struct clipboard_access_params *params,
                    struct clipboard_data *out, void *talloc_ctx)
{
    struct clipboard_mac_priv *p = cl->priv;
    if (params->type != CLIPBOARD_DATA_TEXT)
        return CLIPBOARD_FAILED;
    NSString *text = [p->pasteboard stringForType:NSPasteboardTypeString];
    if (!text)
        text = @"";
    const char *utf8 = [text UTF8String];
    out->type = CLIPBOARD_DATA_TEXT;
    out->u.text = ta_xstrdup(talloc_ctx, utf8 ? utf8 : "");
    return CLIPBOARD_SUCCESS;
}

static int set_data(struct clipboard_ctx *cl, struct clipboard_access_params *params,
                    struct clipboard_data *data)
{
    struct clipboard_mac_priv *p = cl->priv;
    if (params->type != CLIPBOARD_DATA_TEXT || data->type != CLIPBOARD_DATA_TEXT)
        return CLIPBOARD_FAILED;
    NSString *text = [NSString stringWithUTF8String:data->u.text ? data->u.text : ""];
    if (!text)
        text = @"";
    [p->pasteboard clearContents];
    BOOL ok = [p->pasteboard setString:text forType:NSPasteboardTypeString];
    p->change_count = [p->pasteboard changeCount];
    return ok ? CLIPBOARD_SUCCESS : CLIPBOARD_FAILED;
}

static void uninit(struct clipboard_ctx *cl)
{
    struct clipboard_mac_priv *p = cl->priv;
    p->pasteboard = nil;
}

const struct clipboard_backend clipboard_backend_mac = {
    .name = "mac",
    .desc = "macOS clipboard",
    .init = init,
    .uninit = uninit,
    .data_changed = data_changed,
    .get_data = get_data,
    .set_data = set_data,
};
