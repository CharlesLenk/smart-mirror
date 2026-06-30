from scad_export.export import Folder, Model, export

files=Folder(
    name='scad_export/smart_mirror_case',
    contents=[
        Model(name='cable_clip'),
        Model(name='foam_board_frame'),
        Model(name='screen_case'),
        Model(name='snap_brace'),
        Model(name='electronics_case'),
        Model(name='assembly_brace'),
        Model(name='spacer'),
    ]
)

export(files)
