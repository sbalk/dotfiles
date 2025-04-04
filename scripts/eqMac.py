import subprocess
import xml.etree.ElementTree as ET
import xmltodict

xmlstring = subprocess.run(
    "system_profiler SPAudioDataType -xml".split(), capture_output=True
)
tree = ET.fromstring(xmlstring.stdout)
tree_dict = xmltodict.parse(xmlstring.stdout)


def parse(d):
    keys = d.pop("key")
    values = d.pop("string")
    d.update(dict(zip(keys, values)))
    return dict(d)


speakers = tree_dict["plist"]["array"]["dict"]["array"][1]["dict"]["array"]["dict"]
speakers = [parse(s) for s in speakers]
speakers = {s["_name"]: s for s in speakers}

# should be 'eqMac'
default_output_device = next(
    k for k, v in speakers.items() if "coreaudio_default_audio_output_device" in v
)
# should be 'DELL U4021QW'
default_system_output_device = next(
    k for k, v in speakers.items() if "coreaudio_default_audio_system_device" in v
)