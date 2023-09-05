import os
import shutil

def find_files_with_extension(directory, extension):
    file_list = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(extension):
                file_list.append(os.path.join(root, file))
    return file_list

def main():
    working_folder = os.getcwd()
    rrf_files = find_files_with_extension(working_folder, '.rrf')
    unsorted_folder = os.path.join("..", "_unsorted")

    if not os.path.exists(unsorted_folder):
        print(f"Error: {unsorted_folder} does not exist.")
        return

    for rrf_file in rrf_files:
        rrf_mtime = os.path.getmtime(rrf_file)
        files_to_delete = []

        for root, _, files in os.walk(unsorted_folder):
            for file in files:
                file_path = os.path.join(root, file)
                if os.path.getmtime(file_path) == rrf_mtime:
                    files_to_delete.append(file_path)
        
        for file_path in files_to_delete:
            try:
                os.remove(file_path)
                print(f"Deleted: {file_path}")
            except Exception as e:
                print(f"Error deleting {file_path}: {e}")

if __name__ == "__main__":
    main()
