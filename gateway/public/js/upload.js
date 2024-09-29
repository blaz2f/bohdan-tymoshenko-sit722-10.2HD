

//
// Upload a collection of files to the backend.
//
async function uploadFiles(files) {
    for (let i = 0; i < files.length; ++i) {
        await uploadFile(files[i]);
    }
}

//
// Upload a file from the browser to the backend API.
//
async function uploadFile(file) {
    return new Promise((resolve, reject) => {
        const uploadRoute = `/api/upload`;
        fetch(uploadRoute, {
            body: file,
            method: "POST",
            headers: {
                "File-Name": file.name,
                "Content-Type": file.type,
            },
            })
            .then(() => {
                //
                // Display that the upload has completed.
                //
                const resultsElement = document.getElementById("results");
                resultsElement.innerHTML += `<div>${file.name}</div>`;

                //
                // Clear the file form the upload input.
                //
                const uploadInput = document.getElementById("uploadInput");
                uploadInput.value = null;
                resolve();
            })
            .catch((err) => {
                console.error(`Failed to upload: ${file.name}`);
                console.error(err);

                const resultsElement = document.getElementById("results");
                resultsElement.innerHTML += `<div>Failed ${file.name}</div>`;
                reject();
            });
    })}

