const express = require("express");
const { S3 } = require('@aws-sdk/client-s3');
const AWS = require('aws-sdk');
const stream = require('stream');



//
// Throws an error if the any required environment variables are missing.
//
if (!process.env.PORT) {
    throw new Error("Please specify the port number for the HTTP server with the environment variable PORT.");
}

if (!process.env.STORAGE_REGION) {
    throw new Error("Please specify the name of an AWS storage account in environment variable STORAGE_REGION.");
}

if (!process.env.STORAGE_ACCESS_KEY) {
    throw new Error("Please specify the name of an AWS storage account in environment variable STORAGE_ACCESS_KEY.");
}

if (!process.env.STORAGE_SECRET_ACCESS_KEY) {
    throw new Error("Please specify the access key to an AWS storage account in environment variable STORAGE_SECRET_ACCESS_KEY.");
}

if (!process.env.STORAGE_FOLDER_NAME) {
    throw new Error("Please specify the name of an AWS storage account in environment variable STORAGE_FOLDER_NAME.");
}

//
// Extracts environment variables to globals for convenience.
//

const PORT = process.env.PORT;
const STORAGE_REGION = process.env.STORAGE_REGION;
const STORAGE_ACCESS_KEY = process.env.STORAGE_ACCESS_KEY;
const STORAGE_SECRET_ACCESS_KEY = process.env.STORAGE_SECRET_ACCESS_KEY;
const STORAGE_NAME = process.env.STORAGE_NAME;
const STORAGE_FOLDER_NAME = process.env.STORAGE_FOLDER_NAME


console.log(`Serving videos from AWS storage account ${STORAGE_NAME}/${STORAGE_FOLDER_NAME}.`);

const s3AwsClient = new S3({
    credentials: {
        accessKeyId: STORAGE_ACCESS_KEY,
        secretAccessKey: STORAGE_SECRET_ACCESS_KEY
    },
    region: STORAGE_REGION,
});

const app = express();

//
// Registers a HTTP GET route to retrieve videos from storage.
//
app.get("/video", async (req, res) => {

    const videoId = req.query.id; //'SampleVideo_1280x720_1mb.mp4' 

    const params = {
        Bucket: STORAGE_NAME,
        Key: STORAGE_FOLDER_NAME + '/' + videoId + '.mp4'
    };

    // Writes HTTP headers to the response.
    res.writeHead(200, {
        "Content-Type": "video/mp4",
    });

    const s3Object = await s3AwsClient.getObject(params);
    s3Object.Body.pipe(res);
});


//
// HTTP POST route to upload a video to AWS storage.
//

// Define a route to handle file uploads
app.post('/upload', async (req, res) => {
    const videoId = req.headers.id;
    const s3 = new AWS.S3({
        credentials: {
            accessKeyId: STORAGE_ACCESS_KEY,
            secretAccessKey: STORAGE_SECRET_ACCESS_KEY
        },
        region: STORAGE_REGION,
    });
    const uploadStream = ({ Bucket, Key }) => {
        const pass = new stream.PassThrough();
        return {
            writeStream: pass,
            promise: s3.upload({ Bucket, Key, Body: pass }).promise(),
        };
    }
    const { writeStream, promise } = uploadStream({
        Bucket: STORAGE_NAME,
        Key: STORAGE_FOLDER_NAME + '/' + videoId + '.mp4',
        Body: req
    });

    const pipeline = req.pipe(writeStream);
    promise.then(() => {
        console.log('upload completed successfully');
        res.sendStatus(200)
    }).catch((err) => {
        console.log('upload failed.', err.message);
    });
});

//
// Starts the HTTP server.
//
app.listen(PORT, () => {
    console.log(`Microservice online`);
});
